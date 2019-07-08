# DownloadingFileAsset

### AVAsset subclass aimed to work with external cache services

[![CI Status](https://img.shields.io/travis/reedom/DownloadingFileAsset.svg?style=flat)](https://travis-ci.org/reedom/DownloadingFileAsset)
[![Version](https://img.shields.io/cocoapods/v/DownloadingFileAsset.svg?style=flat)](https://cocoapods.org/pods/DownloadingFileAsset)
[![License](https://img.shields.io/cocoapods/l/DownloadingFileAsset.svg?style=flat)](https://cocoapods.org/pods/DownloadingFileAsset)
[![Platform](https://img.shields.io/cocoapods/p/DownloadingFileAsset.svg?style=flat)](https://cocoapods.org/pods/DownloadingFileAsset)

`DownloadingFileAsset` is a subclass of `AVAsset`. It allows you to read or play
a media file under downloading, more resillient with narrow network than the
original.

## Motivation

Media files are getting larger. It's normal to download them from the Internet.
For better UX, apps don't wait to download entire the media but start consuming
as soon as possible in the middle of downloading. But:

- When I used `AVURLAsset(url: localDiskURL)`, it read only available data that
  exists in the local disk at that moment and quittted reading.
- I could use `AVURLAsset(url: remoteURL)` instead, but it means the user would
  download the file twice.

Apple provides the custom resource downloading mechanism what works with `AVURLAsset`
and it will be a help for the situation.  
`DownloadingFileAsset` is a compileed implementation of it.

## Usage

Instantiate `DownloadingFileAsset` with local file URL and its expected file size:

```swift
let asset = DownloadingFileAsset(localFileURL: downloadCacheURL,
                                 expectedFileSize: expectedFileSize)
```

It is supporsed to be available... but not yet. Any asset reading process still ends
with just locally available data.

We needs a workaround for progressive reading:

```swift
// FIXME this is a workaround
self.playerItem = AVPlayerItem(asset: asset)     // both need a strong reference
self.player = AVPlayer(playerItem: playerItem!)
```

Note: for completely downloaded file, use `AVAsset` or any other classes instead.

## Error notifications

Errors will be notified via NotificationCenter. To receive them, you can code like:

```swift
NotificationCenter.default.addObserver(self,
                                       selector: #selector(downloadError),
                                       name: .AssetFileLoaderDelegateFailedToOpenFile,
                                       object: asset.resourceLoader.delegate)
NotificationCenter.default.addObserver(self,
                                       selector: #selector(downloadError),
                                       name: .AssetFileLoaderDelegateReadTimeout,
                                       object: asset.resourceLoader.delegate)

// ...

@objc func downloadError(_ notification: Notification) {
  if let error = notification.userInfo?[AssetFileLoaderDelegateErrorKey] as? Error {
    // manage the error
  }
}
```


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

iOS 9.3+

## Installation

DownloadingFileAsset is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'DownloadingFileAsset'
```

## Author

HANAI tohru, tohru@reedom.com

## License

DownloadingFileAsset is available under the MIT license. See the LICENSE file for more info.
