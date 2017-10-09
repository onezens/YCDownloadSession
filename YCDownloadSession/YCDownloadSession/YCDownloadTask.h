//
//  YCDownloadTask.h
//  YCDownloadSession
//
//  Created by wz on 17/3/15.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Github: https://github.com/onezens/YCDownloadSession
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    YCDownloadStatusWaiting,
    YCDownloadStatusDownloading,
    YCDownloadStatusPaused,
    YCDownloadStatusFinished,
    YCDownloadStatusFailed
} YCDownloadStatus;

/**某一任务下载的状态发生变化的通知*/
static NSString * const kDownloadStatusChangedNoti = @"kDownloadStatusChangedNoti";

@class YCDownloadTask;
@protocol YCDownloadTaskDelegate <NSObject>

@optional

/**
 下载任务的进度回调方法

 @param task 正在下载的任务
 @param downloadedSize 已经下载的文件大小
 @param fileSize 文件实际大小
 */
- (void)downloadProgress:(YCDownloadTask *)task downloadedSize:(NSUInteger)downloadedSize fileSize:(NSUInteger)fileSize;



/**
 下载任务第一次创建的时候的回调

 @param task 创建的任务
 */
- (void)downloadCreated:(YCDownloadTask *)task;


/**
 下载的任务的状态发生改变的回调

 @param status 改变后的状态
 @param task 状态改变的任务
 */
- (void)downloadStatusChanged:(YCDownloadStatus)status downloadTask:(YCDownloadTask *)task;


@end

@interface YCDownloadTask : NSObject

@property (nonatomic, copy) NSString *downloadURL;
@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, assign) NSInteger downloadedSize;
@property (nonatomic, copy, readonly) NSString *saveName;
@property (nonatomic, copy) NSString *tempPath;
@property (nonatomic, weak) id <YCDownloadTaskDelegate>delegate;
/**重新创建下载session，恢复下载状态的session的标识*/
@property (nonatomic, assign) BOOL needToRestart;
@property (nonatomic, assign) YCDownloadStatus downloadStatus;
@property (nonatomic, assign, readonly) NSInteger fileSize;
@property (nonatomic, copy) NSString *tmpName;


/**
 创建一个task

 @param saveName 可以为空，为空的话，savename为下载url的md5加密后的数据
 */
- (instancetype)initWithSaveName:(NSString *)saveName;

/**
 下载进度第一次回调调用，保存文件大小信息
 */
- (void)updateTask;


/**
 根据NSURLSessionTask获取下载的url
 301/302定向的originRequest和currentRequest的url不同，则取原始的
 */
+ (NSString *)getURLFromTask:(NSURLSessionTask *)task;


/**
 根据文件的名称获取文件的沙盒存储路径
 */
+ (NSString *)savePathWithSaveName:(NSString *)saveName;


/**
 获取文件的存储路径的目录
 */
+ (NSString *)saveDir;


@end
