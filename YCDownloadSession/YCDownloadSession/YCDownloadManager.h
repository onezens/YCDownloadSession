//
//  YCDownloadManager.h
//  YCDownloadSession
//
//  Created by wz on 17/3/24.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YCDownloadItem.h"

@interface YCDownloadManager : NSObject


/**
 开始一个后台下载任务
 
 @param downloadURLString 下载url
 */
+ (void)startDownloadWithUrl:(NSString *)downloadURLString fileName:(NSString *)fileName thumbImageUrl:(NSString *)imagUrl;

/**
 暂停一个后台下载任务
 
 @param downloadURLString 下载url
 */
+ (void)pauseDownloadWithUrl:(NSString *)downloadURLString;

/**
 继续开始一个后台下载任务
 
 @param downloadURLString 下载url
 */
+ (void)resumeDownloadWithUrl:(NSString *)downloadURLString;

/**
 删除一个后台下载任务，同时会删除当前任务下载的缓存数据
 
 @param downloadURLString 下载url
 */
+ (void)stopDownloadWithUrl:(NSString *)downloadURLString;


/**
 暂停所有的下载
 */
+ (void)pauseAllDownloadTask;


/**
 根据 downloadURLString 判断该下载是否完成
 */
+ (BOOL)isDownloadWithUrl:(NSString *)downloadURLString;


/**
 根据 downloadURLString 获取该资源的下载状态
 */
+ (YCDownloadStatus)downloasStatusWithUrl:(NSString *)downloadURLString;


/**
 根据 downloadURLString 获取该资源的下载详细信息
 */
+ (YCDownloadItem *)downloadItemWithUrl:(NSString *)downloadURLString;


/**
 获取所有的下载中的资源
 */
+ (NSArray *)downloadList;


/**
 获取所有已完成的下载
 */
+ (NSArray *)finishList;


/**
 获取所有下载数据所占用的磁盘空间
 */
+ (NSUInteger)videoCacheSize;


/**
 获取当前手机的空闲磁盘空间
 */
+ (NSUInteger)fileSystemFreeSize;


/**
 保存下载状态，一般不用，下载内部自己处理完成
 */
+ (void)saveDownloadStatus;


/**
 将文件的字节大小，转换成更加容易识别的大小KB，MB，GB
 */
+ (NSString *)fileSizeStringFromBytes:(uint64_t)byteSize;

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
