#
# Be sure to run `pod lib lint YCDownloadSession.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YCDownloadSession'
  s.version          = '3.0.0'
  s.summary          = 'iOS background download file lib.'
  s.description      = <<-DESC
  iOS background download file lib
                       DESC
  s.homepage     = "https://github.com/onezens/YCDownloadSession"
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "onezens" => "mail@onezen.cc" }
  s.source       = { :git => "https://github.com/onezens/YCDownloadSession.git", :tag => "#{s.version}" }
  s.ios.deployment_target = '10.0'
  
  s.subspec 'Core' do |c|
    c.source_files  = "YCDownloadSession/Core/**/*.{h,m}"
    c.public_header_files = "YCDownloadSession/Core/Public/**/*.h"
  end

  s.subspec 'Mgr' do |m|
    m.dependency 'YCDownloadSession/Core'
    m.source_files  = "YCDownloadSession/Manager/**/*.{h,m}"
    m.public_header_files = "YCDownloadSession/Manager/Public/**/*.{h,m}"
  end
  
  s.subspec 'DB' do |d|
    d.dependency 'YCDownloadSession/Mgr'
    d.source_files  = "YCDownloadSession/Database/**/*.{h,m}"
    d.public_header_files = "YCDownloadSession/Database/Public/**/*.{h,m}"
  end

  s.default_subspec = 'Core'
  s.frameworks = 'CFNetwork'
end
