//
//  ViewController.swift
//  DownloadingFileAsset_Example
//
//  Created by HANAI tohru on 07/08/2019.
//  Copyright (c) 2019 HANAI tohru. All rights reserved.
//

import UIKit
import AVFoundation
import DownloadingFileAsset

class ViewController: UIViewController {

  @IBOutlet var startDownloadingButton: UIButton!
  @IBOutlet var startReadingButton: UIButton!
  @IBOutlet var loadingProgressView: UIProgressView!
  @IBOutlet var readPositionView: UIProgressView!

  private var sourcePath: String!
  private var downloadSize: Int64!
  private let downloader = FakeDownloader()
  private var downloadURL: URL?

  private var playerItem: AVPlayerItem?
  private var player: AVPlayer?

  override func viewDidLoad() {
    super.viewDidLoad()

    sourcePath = Bundle.main.path(forResource: "en_US_36sec", ofType: "mp3")!
    let attr = try! FileManager.default.attributesOfItem(atPath: sourcePath)
    downloadSize = attr[FileAttributeKey.size] as? Int64

    startReadingButton.isEnabled = false
  }

  @IBAction func didTapStartDownloading() {
    startDownloadingButton.isEnabled = false

    if downloadURL == nil {
      // On the first call;
      startReadingButton.isEnabled = true
    }

    downloadURL = downloader.simulateSlowDownload(sourceURL: URL(fileURLWithPath: sourcePath)) { remains in
      self.loadingProgressView.progress = 1.0 - Float(remains) / Float(self.downloadSize)
      if remains == 0 {
        self.startDownloadingButton.isEnabled = true
      }
    }
  }

  @IBAction func didTapStartReading() {
    startReadingButton.isEnabled = false

    let asset = createAsset()

    DispatchQueue.global().async {
      readSampleData(asset: asset) { (read, total) in
        NSLog("read \(read) / \(total)")
        DispatchQueue.main.async {
          self.readPositionView.progress = Float(read) / Float(total)
        }
      }

      DispatchQueue.main.async {
        self.startReadingButton.isEnabled = true
      }
    }
  }

  func createAsset() -> AVAsset {
    guard let downloadURL = downloadURL else { fatalError() }
    let asset = DownloadingFileAsset(localFileURL: downloadURL, expectedFileSize: downloadSize)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(downloadError),
                                           name: .AssetFileLoaderDelegateFailedToOpenFile,
                                           object: asset.resourceLoader.delegate)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(downloadError),
                                           name: .AssetFileLoaderDelegateReadTimeout,
                                           object: asset.resourceLoader.delegate)

    // FIXME: replace the following procudure somehow.
    // This workaround is needed to keep active the sample data reading till EOF.
    playerItem = AVPlayerItem(asset: asset)
    player = AVPlayer(playerItem: playerItem!)

    return asset
  }

  @objc func downloadError(_ notification: Notification) {
    if let error = notification.userInfo?[AssetFileLoaderDelegateErrorKey] as? Error {
      NSLog("Error: \(error.localizedDescription), error: \(error)")
    }
  }
}
