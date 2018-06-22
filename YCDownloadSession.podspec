#
#  Be sure to run `pod spec lint YCDownloadSession.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "YCDownloadSession"
  s.version      = "1.2.6"
  s.summary      = "iOS background download video or file"
  s.description  = <<-DESC
                    iOS background download video or file lib
                   DESC
  s.homepage     = "https://github.com/onezens/YCDownloadSession"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"
  s.license      = "MIT"
  s.author             = { "onezens" => "mail@onezen.cc" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/onezens/YCDownloadSession.git", :tag => "#{s.version}" }
  s.source_files  = "YCDownloadSession/YCDownloadSession/*.{h,m}"
  s.public_header_files = "YCDownloadSession/YCDownloadSession/*.h"
  s.requires_arc = true

end
