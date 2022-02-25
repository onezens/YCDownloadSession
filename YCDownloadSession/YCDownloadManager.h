//
//  YCDownloadManager.h
//  YCDownloadSession
//
//  Created by wz on 17/3/24.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Contact me: http://www.onezen.cc/about/
//  Github:     https://github.com/onezens/YCDownloadSession
//


#import <UIKit/UIKit.h>
#import "YCDownloadItem.h"
#import "YCDownloader.h"

@interface YCDConfig: NSObject
/**
 设置用户标识
 */
@property (nonatomic, copy, nullable) NSString *uid;

/**
 文件保存根路径，默认是Library/Cache/YCDownload目录，系统磁盘不足时，会被系统清理
 更多信息:https://developer.apple.com/library/content/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html#//apple_ref/doc/uid/TP40010672-CH2-SW2
 */
@property (nonatomic, copy, nullable) NSString *saveRootPath;

/**
 最大下载任务个数
 */
@property (nonatomic, assign) NSUInteger maxTaskCount;


@property (nonatomic, assign) YCDownloadTaskCacheMode taskCachekMode;

/**
 冷启动是否自动恢复下载中的任务，否则会暂停所有任务
 */
@property (nonatomic, assign) BOOL launchAutoResumeDownload;

@end


@interface YCDownloadManager : NSObject

/**
 下载管理配置
 */
+ (void)mgrWithConfig:(nonnull YCDConfig *)config;


/**
 切换用户，更新uid
 */
+ (void)updateUid:(NSString *)uid;

/**
 开始/创建一个后台下载任务。
 
 @param item 下载信息的item
 */
+ (void)startDownloadWithItem:(nonnull YCDownloadItem *)item;

/**
 开始/创建一个后台下载任务。
 
 @param item 下载信息的item
 @param priority 下载任务的task，默认：NSURLSessionTaskPriorityDefault 可选参数：NSURLSessionTaskPriorityLow  NSURLSessionTaskPriorityHigh NSURLSessionTaskPriorityDefault 范围：0.0-1.1
 */
+ (void)startDownloadWithItem:(nonnull YCDownloadItem *)item priority:(float)priority;


/**
 开始/创建一个后台下载任务。

 @param downloadURLString 下载的资源的url
 */
+ (void)startDownloadWithUrl:(nonnull NSString *)downloadURLString;

/**
 开始/创建一个后台下载任务。
 
 @param downloadURLString 下载的资源的url， 不可以为空
 @param fileId 非资源的标识,可以为空，用作下载文件保存的名称
 @param priority 下载任务的task，默认：NSURLSessionTaskPriorityDefault 可选参数：NSURLSessionTaskPriorityLow  NSURLSessionTaskPriorityHigh NSURLSessionTaskPriorityDefault 范围：0.0-1.1
 @param extraData item对应的需要存储在本地数据库中的信息
 */
+ (void)startDownloadWithUrl:(nonnull NSString *)downloadURLString fileId:(nullable NSString *)fileId  priority:(float)priority extraData:(nullable NSData *)extraData;

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

/**
 暂停所有的下载
 */
+ (void)pauseAllDownloadTask;

/**
 开始所有的下载
 */
+ (void)resumeAllDownloadTask;

/**
 清空所有的下载文件缓存，YCDownloadManager所管理的所有文件，不包括YCDownloadSession单独下载的文件
 */
+ (void)removeAllCache;

/**
 获取所有的未完成的下载item
 */
+ (nonnull NSArray *)downloadList;

/**
 获取所有已完成的下载item
 */
+ (nonnull NSArray *)finishList;

/**
 根据fileId获取item
 */
+ (nullable YCDownloadItem *)itemWithFileId:(NSString *)fid;

/**
 根据downloadUrl获取item
 */
+ (nonnull NSArray *)itemsWithDownloadUrl:(nonnull NSString *)downloadUrl;

/**
 获取所有下载数据所占用的磁盘空间，不包括YCDownloadSession单独下载的文件
 */
+ (int64_t)videoCacheSize;

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

@end
