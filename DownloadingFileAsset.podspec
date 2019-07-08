#
# Be sure to run `pod lib lint DownloadingFileAsset.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DownloadingFileAsset'
  s.version          = '0.1.0'
  s.summary          = 'AVAsset subclass aimed to work with external cache services.'

  s.homepage         = 'https://github.com/reedom/DownloadingFileAsset'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'HANAI tohru' => 'tohru@reedom.com' }
  s.source           = { :git => 'https://github.com/reedom/DownloadingFileAsset.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '9.3'
  s.swift_version = "5.0"
  s.source_files = 'DownloadingFileAsset/Classes/**/*'
  s.dependency 'DPUTIUtil'
end
