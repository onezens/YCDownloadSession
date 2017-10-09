//
//  YCDownloadSession.h
//  YCDownloadSession
//
//  Created by wz on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Github: https://github.com/onezens/YCDownloadSession
//

#import <UIKit/UIKit.h>
#import "YCDownloadTask.h"

/**当前下载session中所有的任务下载完成的通知。 不包括失败、暂停的任务*/
static NSString * const kDownloadAllTaskFinishedNoti = @"kAllDownloadTaskFinishedNoti";

typedef void (^BGCompletedHandler)(void);
@class YCDownloadSession;

@interface YCDownloadSession : NSObject

/**
 设置下载任务的个数，最多支持3个下载任务同时进行。
 NSURLSession最多支持5个任务同时进行
 但是5个任务，在某些情况下，部分任务会出现等待的状态，所有设置最多支持3个
 */
@property (nonatomic, assign) NSInteger maxTaskCount;

/**
 获取下载session单例
 */
+ (instancetype)downloadSession;


/**
 开始一个后台下载任务
 
 @param downloadURLString 下载url
 @param delegate 下载任务的代理
 @param saveName 下载成功后，需要保存的名称，可以为空，为空的话以url生成保存名称
 */
- (void)startDownloadWithUrl:(NSString *)downloadURLString delegate:(id<YCDownloadTaskDelegate>)delegate saveName:(NSString *)saveName;

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
- (void)resumeDownloadWithUrl:(NSString *)downloadURLString delegate:(id<YCDownloadTaskDelegate>)delegate saveName:(NSString *)saveName;

/**
 删除一个后台下载任务，同时会删除当前任务下载的缓存数据

 @param downloadURLString 下载url
 */
- (void)stopDownloadWithUrl:(NSString *)downloadURLString;


/**
 暂停所有的下载
 */
- (void)pauseAllDownloadTask;

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
 后台某一下载任务完成时，第一次在AppDelegate中的 -(void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
 回调方法中调用该方法。多个task，一个session，只调用一次AppDelegate的回调方法。
 completionHandler 回调执行后，app被系统唤醒的状态会变为休眠状态。

 @param handler 后台任务结束后的调用的处理方法
 @param identifier background session 的标识
 */
-(void)addCompletionHandler:(BGCompletedHandler)handler identifier:(NSString *)identifier;

@end
