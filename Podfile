# Uncomment the next line to define a global platform for your project
platform :ios, '10.0'
target 'YCDownloadSessionDemo' do
  pod 'YCDownloadSession', :path=>'.', :subspecs => ["Core", "Mgr", "DB"]
  pod 'SDWebImage'
  pod 'WMPlayer'
  pod 'Masonry'
  pod 'AFNetworking'
  pod 'MJRefresh'
  pod 'Bugly'

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
          if target.name != "YCDownloadSession"
              config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = "YES"
          end
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '10.0'
      end
    end
end
