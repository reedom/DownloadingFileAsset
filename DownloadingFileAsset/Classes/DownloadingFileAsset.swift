//
//  PlayerItemForDownloadingFile.swift
//  PlayerItemForDownloadingFile
//
//  Created by HANAI Tohru on 2019/07/07.
//  Copyright © 2019 reedom. All rights reserved.
//

import Foundation
import AVFoundation
import DPUTIUtil

extension NSNotification.Name {
  public static let AssetFileLoaderDelegateFailedToOpenFile =
    NSNotification.Name("AssetFileLoaderDelegateFailedToOpenFile")
  public static let AssetFileLoaderDelegateReadTimeout =
    NSNotification.Name("AssetFileLoaderDelegateReadTimeout")
}

public let AssetFileLoaderDelegateErrorKey = "AssetFileLoaderDelegateErrorKey"

// MARK: -

public enum PlayerItemForDownloadingFileError: Error, LocalizedError {
  case readTimeout

  public var errorDescription: String? {
    switch self {
    case .readTimeout:
      return NSLocalizedString("Read timeout.", comment: "PlayerItemForDownloadingFile")
    }
  }
}

open class DownloadingFileAsset: AVURLAsset {
  let PlayerItemForDownloadingFileScheme = "downloadingFileAssetScheme"
  let loader: AssetFileLoaderDelegate

  open var readTimeout: TimeInterval {
    get { return loader.readTimeout }
    set { loader.readTimeout = newValue }
  }

  convenience init(localFilePath: String, expectedFileSize size: Int64, mimeType: String? = nil, options: [String : Any]? = nil) {
    self.init(localFileURL: URL(fileURLWithPath: localFilePath), expectedFileSize: size, mimeType: mimeType, options: options)
  }

  public init(localFileURL: URL, expectedFileSize: Int64, mimeType: String? = nil, options: [String : Any]? = nil) {
    guard
      let urlWithCustomScheme = localFileURL.withScheme(PlayerItemForDownloadingFileScheme)
      else {
        fatalError("Urls without a scheme are not supported")
    }

    loader = AssetFileLoaderDelegate(url: localFileURL, expectedFileSize: expectedFileSize)
    super.init(url: urlWithCustomScheme, options: options)
    resourceLoader.setDelegate(loader, queue: DispatchQueue.global(qos: .utility))
  }
}

open class AssetFileLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
  open var readTimeout: TimeInterval = 30

  let url: URL
  let expectedFileSize: Int64
  let mimeType: String
  private(set) var fileError: Error?
  private(set) var lastReadTime: Date?
  private(set) var fileHandle: FileHandle?

  public init(url: URL, expectedFileSize: Int64, mimeType: String? = nil) {
    self.url = url
    self.expectedFileSize = expectedFileSize
    self.mimeType = mimeType ?? DPUTIUtil.mimeType(fromPath: url.lastPathComponent)

    do {
      fileHandle = try FileHandle(forReadingFrom: url)
    } catch {
      fileError = error
    }
  }

  open func resourceLoader(_ resourceLoader: AVAssetResourceLoader,
                           shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
    if let error = fileError {
      NotificationCenter.default.post(name: .AssetFileLoaderDelegateFailedToOpenFile,
                                      object: self,
                                      userInfo: [AssetFileLoaderDelegateErrorKey: error])
      loadingRequest.finishLoading(with: error)
      return true
    }

    if lastReadTime == nil {
      // Start read timeout measurement.
      lastReadTime = Date()
    }

    if let contentInformationRequest = loadingRequest.contentInformationRequest {
      self.fillInContentInformationRequest(contentInformationRequest)
    }
    guard self.haveEnoughDataToFulfillRequest(loadingRequest) else {
      return false
    }
    loadingRequest.finishLoading()
    return true
  }

  open func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
    fileHandle?.closeFile()
  }

  func fillInContentInformationRequest(_ contentInformationRequest: AVAssetResourceLoadingContentInformationRequest) {
    contentInformationRequest.contentType = mimeType
    contentInformationRequest.contentLength = expectedFileSize
    contentInformationRequest.isByteRangeAccessSupported = true
  }

  func haveEnoughDataToFulfillRequest(_ loadingRequest: AVAssetResourceLoadingRequest) -> Bool{
    guard let dataRequest = loadingRequest.dataRequest else { return true }
    guard let fileHandle = fileHandle else {
      fatalError("logically incorrect")
    }

    let requestedOffset = UInt64(dataRequest.requestedOffset)
    let requestedLength = dataRequest.requestedLength

    if fileHandle.offsetInFile != requestedOffset {
      fileHandle.seek(toFileOffset: requestedOffset)
      if fileHandle.offsetInFile != requestedOffset {
        // TODO do we need to check read timeout??
        return true
      }
    }

    let data = fileHandle.readData(ofLength: requestedLength)
    if !data.isEmpty {
      // Got new data.
      lastReadTime = Date()
      dataRequest.respond(with: data)
      return true
    }

    // Check read timeout.
    if let lastReadTime = lastReadTime {
      if readTimeout <= Date().timeIntervalSince(lastReadTime) {
        let error = PlayerItemForDownloadingFileError.readTimeout
        NotificationCenter.default.post(name: .AssetFileLoaderDelegateReadTimeout,
                                        object: self,
                                        userInfo: [AssetFileLoaderDelegateErrorKey: error])
        loadingRequest.finishLoading(with: error)
        return false
      }
    }
    return true
  }
}

fileprivate extension URL {
  func withScheme(_ scheme: String) -> URL? {
    var components = URLComponents(url: self, resolvingAgainstBaseURL: false)
    components?.scheme = scheme
    return components?.url
  }
}
