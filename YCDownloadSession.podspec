#
#  Be sure to run `pod spec lint YCDownloadSession.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
# :tag => "#{s.version}"

Pod::Spec.new do |s|
  s.name         = "YCDownloadSession"
  s.version      = "2.0.1"
  s.summary      = "iOS background download video or file"
  s.homepage     = "https://github.com/onezens/YCDownloadSession"
  s.license      = "MIT"
  s.author       = { "onezens" => "mail@onezen.cc" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/onezens/YCDownloadSession.git", :tag => "#{s.version}" }

  s.subspec 'Core' do |c|
    c.source_files  = "YCDownloadSession/core/*.{h,m}"
    c.public_header_files = "YCDownloadSession/core/*.h"
  end

  s.subspec 'Mgr' do |m|
    m.dependency 'YCDownloadSession/Core'
    m.source_files  = "YCDownloadSession/*.{h,m}"
    m.public_header_files = "YCDownloadSession/*.h"
  end

  s.default_subspec = 'Core','Mgr'
  s.requires_arc = true
end
