// https://github.com/Quick/Quick

import Quick
import Nimble
import DownloadingFileAsset
import AVFoundation

class DownloadingFileAssetSpec: QuickSpec {
  var error: Error?
  var playerItem: AVPlayerItem!
  var player: AVPlayer!

  override func spec() {
    let path = Bundle.main.path(forResource: "en_US_36sec", ofType: "mp3")!
    let url = URL(fileURLWithPath: path)
    let attr = try! FileManager.default.attributesOfItem(atPath: path)
    let size = attr[FileAttributeKey.size] as! Int64

    describe("load a mp3 file") {
      it("can read") {
        let asset = DownloadingFileAsset(localFileURL: url, expectedFileSize: size)
        var totalDuration: TimeInterval = 0
        readSampleData(asset: asset) { (read, total) in
          totalDuration = total
        }
        expect(totalDuration) > 35
      }
    }

    describe("open non-exisiting file") {
      it("should notify") {
        let nonExistFileURL = URL(fileURLWithPath: "/foo/bar.mp3")
        let asset = DownloadingFileAsset(localFileURL: nonExistFileURL, expectedFileSize: size)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.downloadError),
                                               name: .AssetFileLoaderDelegateFailedToOpenFile,
                                               object: asset.resourceLoader.delegate)
        self.error = nil
        readSampleData(asset: asset) { (read, total) in }
        expect(self.error).toNot(beNil())
        expect(self.error?.localizedDescription) == "The file “bar.mp3” doesn’t exist."
      }
    }

    describe("read timeout") {
      it("should notify") {
        let downloader = FakeDownloader()
        let downloadURL = downloader.simulateSlowDownload(sourceURL: url) { _ in }
        let asset = DownloadingFileAsset(localFileURL: downloadURL, expectedFileSize: size)
        asset.readTimeout = 0
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.downloadError),
                                               name: .AssetFileLoaderDelegateReadTimeout,
                                               object: asset.resourceLoader.delegate)
        self.playerItem = AVPlayerItem(asset: asset)
        self.player = AVPlayer(playerItem: self.playerItem)
        self.error = nil

        waitUntil { done in
          readSampleData(asset: asset) { (_, _) in }
          expect(self.error).toNot(beNil())
          expect(self.error?.localizedDescription) == PlayerItemForDownloadingFileError.readTimeout.localizedDescription
          done()
        }

      }
    }
  }

  @objc func downloadError(_ notification: Notification) {
    error = notification.userInfo?[AssetFileLoaderDelegateErrorKey] as? Error
  }
}

