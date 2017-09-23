# YCDownloadSession
通过NSURLSession的创建后台下载任务时，保证了APP在后台或者退出的状态下，依然能后进行下载任务，下载完成后能够唤醒APP来将下载完成的数据保存到需要的位置。

### 功能点介绍
创建一个后台下载的session（创建的task为私有__NSCFBackgroundDownloadTask）：  

```
NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
        NSString *identifier = [NSString stringWithFormat:@"%@.BackgroundSession", bundleId];
        NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        sessionConfig.allowsCellularAccess = true;
        session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                delegate:self
                                           delegateQueue:[NSOperationQueue mainQueue]];


```

1. 在APP处于后台、锁屏状态下依然能后下载
2. 最强大的是：APP在手动退出，闪退的状态下依然能够进行下载任务，下载完成后自动激活APP，进行相关的逻辑处理

### 结构介绍
该视频下载库库主要有四个核心类：YCDownloadSession，YCDownloadTask，YCDownloadItem，YCDownloadManager  

1. YCDownloadSession：对NSURLSession的进一步分装，是一个单例，所有的下载任务都是由其生成和管理。是最主要的核心类。实现了下载的代理方法，通过一个可下载的url，生成一个YCDownloadTask，并且将该task的所有数据进行实时存储。
2. YCDownloadTask 将YCDownloadSession里的代理方法进一步封装和扩展，保存session生成和所需要的一些下载信息和数据。
3. YCDownloadItem 存放需要下载的视频的信息
4. YCDownloadManager 管理下载视频操作，生成一个YCDownloadItem，并且实时保存相关信息(下载状态，文件大小，已下载文件大小，以及其它的需要和UI交互的数据)，然后调用YCDownloadSession去下载该视频。

图解：

![图解](http://src.onezen.cc/demo/download3.png)

YCDownloadSession和YCDownloadTask是两个核心类。与YCDownloadManager和YCDownloadItem相互独立。大家和可以通过YCDownloadSession和YCDownloadTask自定义需要的下载管理类的信息类。



### 用法

1. 直接使用YCDownloadSession

	```
	self.downloadURL = @"http://dldir1.qq.com/qqfile/QQforMac/QQ_V6.0.1.dmg";
	
	- (void)start {
	    [[YCDownloadSession downloadSession] startDownloadWithUrl:self.downloadURL delegate:self];
	}
	- (void)resume {
	    [[YCDownloadSession downloadSession] resumeDownloadWithUrl:self.downloadURL delegate:self];
	}
	
	- (void)pause {
	    [[YCDownloadSession downloadSession] pauseDownloadWithUrl:self.downloadURL];
	}

	- (void)stop {
	    [[YCDownloadSession downloadSession] stopDownloadWithUrl:self.downloadURL];
	}
	
	//代理
	- (void)downloadProgress:(YCDownloadTask *)task totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
	    self.progressLbl.text = [NSString stringWithFormat:@"%f",(float)totalBytesWritten / totalBytesExpectedToWrite * 100];
	}
	
	- (void)downloadFailed:(YCDownloadTask *)task {
	    self.progressLbl.text = @"download failed!";
	}
	
	- (void)downloadinished:(YCDownloadTask *)task {
	    self.progressLbl.text = @"download success!";
	}

	```
	
2. 使用自定义的管理类(YCDownloadManager 视频类型文件专用下载管理类)下载

	```
	//下载列表页面
	VideoListInfoModel *model = [VideoListInfoModel alloc] init];
	//设置model的数据
	...
	[YCDownloadManager startDownloadWithUrl:model.mp4_url fileName:model.title thumbImageUrl:model.cover];
	
	
	//缓存列表页面 
	//YCDownloadItem(存储下载的视频的详细信息，和下载进度回调)
	[YCDownloadManager downloadList]; //正在下载列表
	[YCDownloadManager finishList]; 	//下载完成列表

	
	```

3. 蜂窝煤是否允许下载的方法(YCDownloadSession, YCDownloadManager)

	```
	/**
	 是否允许蜂窝煤网络下载，以及网络状态变为蜂窝煤是否允许下载，必须把所有的downloadTask全部暂停，然后重新创建。否则，原先创建的
	 下载task依旧在网络切换为蜂窝煤网络时会继续下载
	 
	 @param isAllow 是否允许蜂窝煤网络下载
	 */
	- (void)allowsCellularAccess:(BOOL)isAllow;
	
	
	/**
	 获取当前是否允许蜂窝煤访问状态
	 */
	- (BOOL)isAllowsCellularAccess;
	```



### 使用效果图

1. 单文件下载测试

  ![单文件下载测试](http://src.onezen.cc/demo/download/1.gif)

2. 多视频下载测试

  ![多视频下载测试](http://src.onezen.cc/demo/download/2.gif)


### TODO

1. 4G/流量下载管理（完成）
2. 对下载任务个数进一步优化和管理
3. 下载完成后添加本地通知
4. Swift 版的下载


### 下载代码详解

简书blog： [http://www.jianshu.com/p/2ccb34c460fd](http://www.jianshu.com/p/2ccb34c460fd)


使用APP：[https://itunes.apple.com/cn/app/id975958413](https://itunes.apple.com/cn/app/id975958413)

**欢迎各位关注该库，如果你有任何问题请issues我，将会随时更新新功能和解决存在的问题。**

**技术交流QQ群： 304468625**


