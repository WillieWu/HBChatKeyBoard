#
# Be sure to run `pod lib lint HBChatKeyBoard.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'HBChatKeyBoard'
  s.version          = '1.0.2'
  s.summary          = 'A short description of HBChatKeyBoard.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
	Emoticons are for demo only
                       DESC

  s.homepage         = 'https://github.com/WillieWu/HBChatKeyBoard'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'hongbin.wu' => '601479318@qq.com' }
  s.source           = { :git => 'https://github.com/WillieWu/HBChatKeyBoard.git', :tag => s.version.to_s }


  s.ios.deployment_target = '8.0'
  s.source_files = 'HBChatKeyBoard/Classes/**/*', 'HBChatKeyBoard/Classes/*'
  
  # s.resource_bundles = {
  #   'HBChatKeyBoard' => ['HBChatKeyBoard/Assets/*.png', 'HBChatKeyBoard/Assets/**/*.png', 'HBChatKeyBoard/Assets/**/*.plist']
  # }
  s.swift_version = '4.0'
  s.requires_arc = true
  s.frameworks = 'UIKit', 'AVFoundation'
  s.dependency 'SnapKit', '~> 4.0.0'
end
