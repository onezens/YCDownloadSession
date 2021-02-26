# [YCDownloadSession](https://onezens.github.io/YCDownloadSession/)

[![Platform](https://img.shields.io/badge/platform-iOS-yellowgreen.svg)](https://github.com/onezens/YCDownloadSession)
[![Support](https://img.shields.io/badge/support-iOS%208%2B%20-blue.svg?style=flat)](https://www.apple.com/nl/ios/)
[![CocoaPods](http://img.shields.io/cocoapods/v/YCDownloadSession.svg?style=flat)](https://cocoapods.org/pods/YCDownloadSession)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Build Status](https://travis-ci.com/onezens/YCDownloadSession.svg?branch=master)](https://travis-ci.com/onezens/YCDownloadSession)



## 通过Cocoapods安装

安装Cocoapods

```
$ brew install ruby
$ sudo gem install cocoapods
```

**Podfile**

分成主要两个包:

- `Core` : YCDownloader 只有下载器
- `Mgr`  : YCDownloader , YCDownloadManager 所有

```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

target 'TargetName' do
    pod 'YCDownloadSession', '~> 2.0.2', :subspecs => ['Core', 'Mgr']
end
```

然后安装依赖库：

```
$ pod install
```

提示错误 `[!] Unable to find a specification for YCDownloadSession ` 解决办法：

```
$ pod repo update master
```
## 通过Carthage安装
安装carthage：

```
brew install carthage
```
添加下面配置到`Cartfile`里：

```
github "onezens/YCDownloadSession"
```
安装, 然后添加Framework到项目：

```
carthage update --platform ios
```

## 用法

**引用头文件**

```
#import <YCDownloadSession.h>
```


**AppDelegate设置后台下载成功回调方法**

```
-(void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler{
    [[YCDownloader downloader] addCompletionHandler:completionHandler identifier:identifier];
}
```

### 下载器 `YCDownloader`

创建下载任务

```
YCDownloadTask *task = [[YCDownloader downloader] downloadWithUrl:@"download_url" progress:^(NSProgress * _Nonnull progress, YCDownloadTask * _Nonnull task) {
    NSLog(@"progress: %f", progress.fractionCompleted); 
} completion:^(NSString * _Nullable localPath, NSError * _Nullable error) {
    // handler download task completed callback
}];
```

开始下载任务：

```
[[YCDownloader downloader] resumeTask:self.downloadTask];
```

暂停下载任务：

```
[[YCDownloader downloader] pauseTask:self.downloadTask];
```

删除下载任务：

```
[[YCDownloader downloader] cancelTask:self.downloadTask];
```

异常退出应用后，恢复之前正在进行的任务的回调

```
/**
 恢复下载任务，继续下载任务，主要用于app异常退出状态恢复，继续下载任务的回调设置

 @param tid 下载任务的taskId
 @param progress 下载进度回调
 @param completion 下载成功失败回调
 @return 下载任务task
 */
- (nullable YCDownloadTask *)resumeDownloadTaskWithTid:(NSString *)tid progress:(YCProgressHandler)progress completion:(YCCompletionHandler)completion;
```

### 下载任务管理器`YCDownloadManager`

设置任务管理器配置

```
NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
path = [path stringByAppendingPathComponent:@"download"];
YCDConfig *config = [YCDConfig new];
config.saveRootPath = path;
config.uid = @"100006";
config.maxTaskCount = 3;
config.taskCachekMode = YCDownloadTaskCacheModeKeep;
config.launchAutoResumeDownload = true;
[YCDownloadManager mgrWithConfig:config];
```

下载任务相关通知

```
//某一个YCDownloadItem下载成功通知
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadTaskFinishedNoti:) name:kDownloadTaskFinishedNoti object:nil];
//mgr 管理的所有任务完成通知
[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadAllTaskFinished) name:kDownloadTaskAllFinishedNoti object:nil];
```

开始下载任务

```
YCDownloadItem *item = [YCDownloadItem itemWithUrl:model.mp4_url fileId:model.file_id];
item.extraData = ...;
[YCDownloadManager startDownloadWithItem:item];
```
下载相关控制

```
/**
暂停一个后台下载任务
     
@param item 创建的下载任务item
*/
+ (void)pauseDownloadWithItem:(nonnull YCDownloadItem *)item;
    
/**
继续开始一个后台下载任务
     
@param item 创建的下载任务item
*/
+ (void)resumeDownloadWithItem:(nonnull YCDownloadItem *)item;
    
/**
删除一个后台下载任务，同时会删除当前任务下载的缓存数据
     
@param item 创建的下载任务item
*/
+ (void)stopDownloadWithItem:(nonnull YCDownloadItem *)item;
```
蜂窝煤网络访问控制

```
/**
是否允许蜂窝煤网络下载，以及网络状态变为蜂窝煤是否允许下载，必须把所有的downloadTask全部暂停，然后重新创建。否则，原先创建的
下载task依旧在网络切换为蜂窝煤网络时会继续下载
     
@param isAllow 是否允许蜂窝煤网络下载
*/
+ (void)allowsCellularAccess:(BOOL)isAllow;
    
/**
获取是否允许蜂窝煤访问
*/
+ (BOOL)isAllowsCellularAccess;
```

## 使用效果图

单文件下载测试

![单文件下载测试](http://src.onezen.cc/demo/download/1.gif)

多视频下载测试

![多视频下载测试](http://src.onezen.cc/demo/download/2.gif)
  
下载通知

![下载通知](http://src.onezen.cc/demo/download/4.png)


