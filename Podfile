# Uncomment the next line to define a global platform for your project
target 'YCDownloadSessionDemo' do
  pod 'YCDownloadSession', :path=>'./'
  pod 'SDWebImage'
  pod 'WMPlayer'
  pod 'Masonry'
  pod 'AFNetworking'
  pod 'MJRefresh'
  pod 'Bugly'
  
  target 'YCDownloadSessionDemoTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

target 'YCDownloadSession' do
    use_frameworks!
    pod 'YCDownloadSession', :path=>'./'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
          if target.name != "YCDownloadSession"
              config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = "YES"
              config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '9.0'
          end
      end
    end
end
