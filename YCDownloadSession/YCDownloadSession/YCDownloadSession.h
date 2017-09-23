//
//  YCDownloadSession.h
//  YCDownloadSession
//
//  Created by wz on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YCDownloadTask.h"

@class YCDownloadSession;
@interface YCDownloadSession : NSObject

/**
 获取下载session单例
 */
+ (instancetype)downloadSession;


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


/**
 开始一个后台下载任务
 
 @param downloadURLString 下载url
 @param delegate 下载任务的代理
 */
- (void)startDownloadWithUrl:(NSString *)downloadURLString delegate:(id<YCDownloadTaskDelegate>)delegate;

/**
 暂停一个后台下载任务
 
 @param downloadURLString 下载url
 */
- (void)pauseDownloadWithUrl:(NSString *)downloadURLString;

/**
 继续开始一个后台下载任务
 
 @param downloadURLString 下载url
 @param delegate 下载任务的代理
 */
- (void)resumeDownloadWithUrl:(NSString *)downloadURLString delegate:(id<YCDownloadTaskDelegate>)delegate;

/**
 删除一个后台下载任务，同时会删除当前任务下载的缓存数据

 @param downloadURLString 下载url
 */
- (void)stopDownloadWithUrl:(NSString *)downloadURLString;


/**
 暂停所有的下载
 */
- (void)pauseAllDownloadTask;



@end
