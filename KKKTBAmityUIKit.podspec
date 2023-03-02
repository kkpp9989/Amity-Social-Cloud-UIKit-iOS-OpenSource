#
# Be sure to run `pod lib lint KKPodLib1.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#
# KK 
# pod lib lint --swift-version=5.0
# pod trunk push --swift-version=5.0

Pod::Spec.new do |s|
  s.name             = 'KKKTBAmityUIKit'
  s.version          = '1.0.1'
  s.summary          = 'Init AmityUIKit'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'Custom AmityUIKit For ONE KrungThai APP'

  s.homepage         = 'https://github.com/kkpp9989/Amity-Social-Cloud-UIKit-iOS-OpenSource'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'kkpp9989' => 'ninratana.n@gmail.com' }
  s.source           = { :git => 'https://github.com/kkpp9989/Amity-Social-Cloud-UIKit-iOS-OpenSource.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '12.0'
  s.swift_version = '5.0'
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '5' }


  # s.source_files = 'AmityFramework/uikit.zip'
  # s.source = { :http => 'https://sdk.amity.co/sdk-release/ios-uikit/2.34.3/uikit.zip'}
  # s.preserve_path = 'AmityFramework/*'
  s.ios.vendored_frameworks = 'AmityFramework/AmitySDK.xcframework', 'AmityFramework/AmityUIKit.xcframework'

  # s.resource_bundles = {
  #   'KKPodLib1' => ['KKPodLib1/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'Realm', '~> 10.26.0'
end
