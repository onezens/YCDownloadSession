# YCDownloadSession
后台下载视频，通过NSURLSession的后台下载任务下载视频的时候，保证在APP后台或者退出的状态下，依然能后进行下载任务，下载完成后能够唤醒APP来将下载完成的数据保存到需要的位置。

### 结构介绍
该视频下载库库主要有四个核心类：YCDownloadSession，YCDownloadTask，YCDownloadItem，YCDownloadManager  

1. YCDownloadSession：对NSURLSession的进一步分装，是一个单例，所有的下载任务都是由其生成和管理。是最主要的核心类。实现了下载的代理方法，通过一个可下载的url，生成一个YCDownloadTask，并且将该task的所有数据进行实时存储。
2. YCDownloadTask 将YCDownloadSession里的代理方法进一步封装和扩展，保存session生成和所需要的一些下载信息和数据。
3. YCDownloadItem 存放需要下载的视频的信息
4. YCDownloadManager 管理下载视频操作，生成一个YCDownloadItem，并且实时保存相关信息(下载状态，文件大小，已下载文件大小，以及其它的需要和UI交互的数据)，然后调用YCDownloadSession去下载该视频。

图解：

![图解](http://src.onezen.cc/demo/download3.png)

YCDownloadSession和YCDownloadTask是两个核心类。与YCDownloadManager和YCDownloadItem相互独立。大家和可以通过YCDownloadSession和YCDownloadTask自定义需要的下载管理类的信息类。


### 使用效果图

1. 单文件下载测试
![单文件下载测试](http://src.onezen.cc/demo/download/1.gif)

2. 多视频下载测试
![多视频下载测试](http://src.onezen.cc/demo/download/2.gif)


### TODO

1. 4G/流量下载管理
2. 对下载任务个数进一步优化和管理


