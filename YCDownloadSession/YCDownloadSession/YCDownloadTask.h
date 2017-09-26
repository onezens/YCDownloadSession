//
//  YCDownloadTask.h
//  YCDownloadSession
//
//  Created by wz on 17/3/15.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum : NSUInteger {
    YCDownloadStatusWaiting,
    YCDownloadStatusDownloading,
    YCDownloadStatusPaused,
    YCDownloadStatusFinished,
    YCDownloadStatusFailed
} YCDownloadStatus;

static NSString * const kYCDownloadSessionSaveDownloadStatus = @"kYCDownloadSessionSaveDownloadStatus";

@class YCDownloadTask;
@protocol YCDownloadTaskDelegate <NSObject>

@optional

/**
 下载任务的进度回调方法

 @param task 正在下载的任务
 @param totalBytesWritten 已经下载的文件大小
 @param totalBytesExpectedToWrite 期望下载的文件大小
 */
- (void)downloadProgress:(YCDownloadTask *)task totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;


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
@property (nonatomic, assign) BOOL needToRestart;
@property (nonatomic, assign) YCDownloadStatus downloadStatus;

@property (nonatomic, assign, readonly) NSInteger fileSize;



+ (NSString *)getURLFromTask:(NSURLSessionTask *)task;

- (void)updateTask;

+ (NSString *)savePathWithSaveName:(NSString *)saveName;

+ (NSString *)saveDir;


@end
