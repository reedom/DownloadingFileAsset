//
//  FakeDownloader.swift
//  DownloadingFileAsset_Example
//
//  Created by HANAI Tohru on 2019/07/07.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Foundation

class FakeDownloader {
  func simulateSlowDownload(sourceURL: URL, progressHandler: @escaping (_ remains: Int) -> Void) -> URL {
    let fileManager = FileManager.default

    // setup destination URL
    let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
    let downloadURL = cacheDir.appendingPathComponent(sourceURL.lastPathComponent)
    try? fileManager.removeItem(at: downloadURL)
    assert(!fileManager.fileExists(atPath: downloadURL.path))

    // Simulate downloading; start from the first 8KB and then write eventually 5KB/100ms.
    let sourceData = try! Data(contentsOf: sourceURL)
    NSLog("Simulate download \(sourceURL.lastPathComponent)")

    let stream = OutputStream(toFileAtPath: downloadURL.path, append: false)!
    stream.open()
    _ = sourceData.withUnsafeBytes() { bytes in
      let buffer: UnsafePointer<UInt8> = bytes.baseAddress!.assumingMemoryBound(to: UInt8.self)
      var wrote = stream.write(buffer, maxLength: 1024*8)
      NSLog("wrote \(wrote / 1024)/\(sourceData.count / 1024)KB")
      var remains = sourceData.count - 1024*8
      progressHandler(remains)

      DispatchQueue.global().async {
        while 0 < remains {
          usleep(100 * 1000)
          let n = min(remains, 1024*5)
          wrote += stream.write(buffer + wrote, maxLength: n)
          if let error = stream.streamError {
            print(error)
          } else {
            remains -= n
            NSLog("wrote \(wrote / 1024)/\(sourceData.count / 1024)KB")
            DispatchQueue.main.sync {
              progressHandler(remains)
            }
          }
        }
        print("done")
        stream.close()
      }
    }
    assert(fileManager.fileExists(atPath: downloadURL.path))

    return downloadURL
  }
}

