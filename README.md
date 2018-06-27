# [YCDownloadSession](https://onezens.github.io/YCDownloadSession/)

[![Platform](https://img.shields.io/badge/platform-iOS-yellowgreen.svg)](https://github.com/onezens/YCDownloadSession)
[![GitHub license](https://img.shields.io/github/license/onezens/YCDownloadSession.svg)](https://github.com/onezens/YCDownloadSession/blob/master/LICENSE)


## 通过Cocoapods安装

安装Cocoapods

```
$ brew install ruby
$ sudo gem install cocoapods
```

**Podfile**

```
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'

target 'TargetName' do
    pod 'YCDownloadSession', '~> 1.2.6'
end
```

然后安装依赖库：

```
$ pod install
```

提示错误 `[!] Unable to find a specification for YCDownloadSession ` 解决办法：

```
$ pod setup
```

## 用法

1. AppDelegate设置后台下载成功回调方法

	```
	-(void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler{
	    [[YCDownloadSession downloadSession] addCompletionHandler:completionHandler];
	}
	
	```


2. 直接使用YCDownloadSession下载文件

	```
	self.downloadURL = @"http://dldir1.qq.com/qqfile/QQforMac/QQ_V6.0.1.dmg";
	


    - (void)start {
        self.downloadTask = [YCDownloadSession.downloadSession startDownloadWithUrl:self.downloadURL fileId:nil delegate:self];
    }
    - (void)resume {
        [self.downloadTask resume];
    }
    
    - (void)pause {
        [self.downloadTask pause];
    }
    
    - (void)stop {
        [self.downloadTask remove];
    }
    	
    //代理
    - (void)downloadProgress:(YCDownloadTask *)task downloadedSize:(NSUInteger)downloadedSize fileSize:(NSUInteger)fileSize {
        self.progressLbl.text = [NSString stringWithFormat:@"%f",(float)downloadedSize / fileSize * 100];
    }
    
    
    - (void)downloadStatusChanged:(YCDownloadStatus)status downloadTask:(YCDownloadTask *)task {
        if (status == YCDownloadStatusFinished) {
            self.progressLbl.text = @"download success!";
            NSLog(@"save file path: %@", task.savePath);
        }else if (status == YCDownloadStatusFailed){
            self.progressLbl.text = @"download failed!";
        }
    }

	```
	
3. YCDownloadManager 为视频类型文件专用下载管理类

	```
    /**
     开始/创建一个后台下载任务。downloadURLString作为整个下载任务的唯一标识。
     下载成功后用downloadURLString的MD5的值来保存
     文件后缀名取downloadURLString的后缀名，[downloadURLString pathExtension]
    
     @param downloadURLString 下载的资源的url
     @param fileName 资源名称,可以为空
     @param imagUrl 资源的图片,可以为空
     */
    + (void)startDownloadWithUrl:(NSString *)downloadURLString fileName:(NSString *)fileName imageUrl:(NSString *)imagUrl;
    
    /**
     开始/创建一个后台下载任务。downloadURLString作为整个下载任务的唯一标识。
     下载成功后用fileId来保存, 要确保fileId唯一
     文件后缀名取downloadURLString的后缀名，[downloadURLString pathExtension]
     
     @param downloadURLString 下载的资源的url， 不可以为空， 下载任务标识
     @param fileName 资源名称,可以为空
     @param imagUrl 资源的图片,可以为空
     @param fileId 非资源的标识,可以为空，用作下载文件保存的名称
     */
    + (void)startDownloadWithUrl:(NSString *)downloadURLString fileName:(NSString *)fileName imageUrl:(NSString *)imagUrl fileId:(NSString *)fileId;

    
        /**
     暂停一个后台下载任务
     
     @param item 创建的下载任务item
     */
    + (void)pauseDownloadWithItem:(YCDownloadItem *)item;
    
    /**
     继续开始一个后台下载任务
     
     @param item 创建的下载任务item
     */
    + (void)resumeDownloadWithItem:(YCDownloadItem *)item;
    
    /**
     删除一个后台下载任务，同时会删除当前任务下载的缓存数据
     
     @param item 创建的下载任务item
     */
    + (void)stopDownloadWithItem:(YCDownloadItem *)item;
    
    /**
     暂停所有的下载
     */
    + (void)pauseAllDownloadTask;

	
	```

4. 蜂窝煤是否允许下载的方法(YCDownloadSession, YCDownloadManager)

	```
	YCDownloadSession: 
	/**
	 是否允许蜂窝煤网络下载，以及网络状态变为蜂窝煤是否允许下载，必须把所有的downloadTask全部暂停，然后重新创建。否则，原先创建的
	 下载task依旧在网络切换为蜂窝煤网络时会继续下载
	 
	 @param isAllow 是否允许蜂窝煤网络下载
	 */
	- (void)allowsCellularAccess:(BOOL)isAllow;
	
	YCDownloadManager:
	/**
	 获取当前是否允许蜂窝煤访问状态
	 */
	- (BOOL)isAllowsCellularAccess;
	```

5. 设置最大同时进行下载的任务数

	```
	YCDownloadSession: 
	/**
	 设置下载任务的个数，最多支持3个下载任务同时进行。
	 NSURLSession最多支持5个任务同时进行
	 但是5个任务，在某些情况下，部分任务会出现等待的状态，所有设置最多支持3个
	 */
	@property (nonatomic, assign) NSInteger maxTaskCount;
	
	
	
	YCDownloadManager:
	/**
	 设置下载任务的个数，最多支持3个下载任务同时进行。
	 */
	+ (void)setMaxTaskCount:(NSInteger)count;
	```
	
6. 下载完成的通知
	* 当前session中所有的任务下载完成的通知。 不包括失败、暂停的任务: `kDownloadAllTaskFinishedNoti`
	* 某一的任务下载完成的通知object为YCDownloadItem对象：`kDownloadTaskFinishedNoti`

7. 某一任务下载的状态发生变化的通知: `kDownloadStatusChangedNoti` 主要用于状态改变后，及时保存下载数据信息。



## 使用效果图

1. 单文件下载测试

  ![单文件下载测试](http://src.onezen.cc/demo/download/1.gif)

2. 多视频下载测试

  ![多视频下载测试](http://src.onezen.cc/demo/download/2.gif)
  
3. 下载通知

  ![下载通知](http://src.onezen.cc/demo/download/4.png)


## TODO

* [x] 4G/流量下载管理
* [x] 对下载任务个数进一步优化和管理
* [x]  下载完成后添加本地通知
* [x] 301/302 视频模拟测试
* [ ] Swift 版的下载 - 第一个稳定版发布后开始 (正在进行)


## 关于

* 如何反馈问题：[Bug_report.md](https://github.com/onezens/YCDownloadSession/blob/master/.github/ISSUE_TEMPLATE/Bug_report.md)



