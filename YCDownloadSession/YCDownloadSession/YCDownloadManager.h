//
//  YCDownloadManager.h
//  YCDownloadSession
//
//  Created by wz on 17/3/24.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Contact me: http://www.onezen.cc
//  Github:     https://github.com/onezens/YCDownloadSession
//

#import <UIKit/UIKit.h>
#import "YCDownloadItem.h"
#import "YCDownloadSession.h"

@interface YCDownloadManager : NSObject

/**
 设置下载任务的个数，最多支持3个下载任务同时进行。
 */
+ (void)setMaxTaskCount:(NSInteger)count;


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

/**
 开始所有的下载
 */
+ (void)resumeAllDownloadTask;


/**
 清空所有的下载文件缓存，YCDownloadManager所管理的所有文件，不包括YCDownloadSession单独下载的文件
 */
+ (void)removeAllCache;

/**
 根据 downloadId 判断该下载是否已经创建
 @param downloadId 创建的下载任务的标识。如果有fileId使用fileId,没有则是downloadURLString
 */
+ (BOOL)isDownloadWithId:(NSString *)downloadId;

/**
 根据 downloadId 获取该资源的下载状态
 @param downloadId 创建的下载任务的标识。如果有fileId使用fileId,没有则是downloadURLString
 */
+ (YCDownloadStatus)downloasStatusWithId:(NSString *)downloadId;

/**
 根据 downloadId 获取该资源的下载详细信息
 @param downloadId 创建的下载任务的标识。如果有fileId使用fileId,没有则是downloadURLString
 */
+ (YCDownloadItem *)downloadItemWithId:(NSString *)downloadId;

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

/**
 本地通知的开关，默认是false,可以根据通知名称自定义通知类型
 */
+ (void)localPushOn:(BOOL)isOn;


@end
