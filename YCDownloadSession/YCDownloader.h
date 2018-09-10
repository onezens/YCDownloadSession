//
//  YCDownload.h
//  YCDownloadSession
//
//  Created by wz on 2018/8/27.
//  Copyright © 2018 onezen.cc. All rights reserved.
//  Contact me: http://www.onezen.cc/about/
//  Github:     https://github.com/onezens/YCDownloadSession
//

#import <Foundation/Foundation.h>
#import "YCDownloadTask.h"
typedef void (^BGCompletedHandler)(void);

/**
 下载完成后的数据处理行为
 - YCDownloadTaskCacheModeDefault: 下载完成后，删除库中的下载数据
 - YCDownloadTaskCacheModeKeep: 下载完成后，不删除库中的下载数据
 */
typedef NS_ENUM(NSUInteger, YCDownloadTaskCacheMode) {
    YCDownloadTaskCacheModeDefault,
    YCDownloadTaskCacheModeKeep
};

@interface YCDownloader : NSObject
/**
 是否允许蜂窝煤网络下载
 */
@property (nonatomic, assign) BOOL allowsCellularAccess;

/**
 下载完成后的数据处理行为
 */
@property (nonatomic, assign) YCDownloadTaskCacheMode taskCachekMode;

+ (instancetype)downloader;

- (YCDownloadTask *)downloadWithUrl:(NSString *)url progress:(YCProgressHanlder)progress completion:(YCCompletionHanlder)completion;

- (YCDownloadTask *)downloadWithRequest:(NSURLRequest *)request progress:(YCProgressHanlder)progress completion:(YCCompletionHanlder)completion;

- (YCDownloadTask *)downloadWithRequest:(NSURLRequest *)request progress:(YCProgressHanlder)progress completion:(YCCompletionHanlder)completion priority:(float)priority;

- (YCDownloadTask *)resumeDownloadTaskWithTid:(NSString *)tid progress:(YCProgressHanlder)progress completion:(YCCompletionHanlder)completion;

- (BOOL)resumeDownloadTask:(YCDownloadTask *)task;

- (void)pauseDownloadTask:(YCDownloadTask *)task;

- (void)cancelDownloadTask:(YCDownloadTask *)task;

/**
 后台某一下载任务完成时，第一次在AppDelegate中的 -(void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
 回调方法中调用该方法。多个task，一个session，只调用一次AppDelegate的回调方法。
 completionHandler 回调执行后，app被系统唤醒的状态会变为休眠状态。
 
 @param handler 后台任务结束后的调用的处理方法
 @param identifier background session 的标识
 */
-(void)addCompletionHandler:(BGCompletedHandler)handler identifier:(NSString *)identifier;

@end
