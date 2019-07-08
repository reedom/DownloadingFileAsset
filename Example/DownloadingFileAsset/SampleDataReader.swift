//
//  SampleDataReader.swift
//  DownloadingFileAsset_Example
//
//  Created by HANAI Tohru on 2019/07/08.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import AVFoundation

public func readSampleData(asset: AVAsset, readHandler: @escaping (_ read: TimeInterval, _ total: TimeInterval) -> Void) {
  guard
    let track = asset.tracks.first,
    let reader = try? AVAssetReader(asset: asset)
    else {
      NSLog("Cannot read sample data")
      return
  }

  let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: nil)
  readerOutput.alwaysCopiesSampleData = false
  reader.add(readerOutput)

  // 16-bit samples
  reader.startReading()
  defer { reader.cancelReading() }

  var readDuration: TimeInterval = 0
  var totalDuration: TimeInterval?

  // var remainBytes = Int(ceil(duration.duration.seconds * Double(sampleRate))) * channelCount * MemoryLayout<Int16>.size
  while let sample = readerOutput.copyNextSampleBuffer(), CMSampleBufferIsValid(sample) {
    readDuration += CMSampleBufferGetDuration(sample).seconds
    CMSampleBufferInvalidate(sample)

    if let totalDuration = totalDuration {
      readHandler(readDuration, totalDuration)
    } else if 0 < asset.duration.seconds {
      totalDuration = asset.duration.seconds
      readHandler(readDuration, totalDuration!)
    }
  }
  NSLog("read done")
}
