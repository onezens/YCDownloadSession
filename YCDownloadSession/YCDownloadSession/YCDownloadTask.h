//
//  YCDownloadTask.h
//  YCDownloadSession
//
//  Created by wz on 17/3/15.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Contact me: http://www.onezen.cc
//  Github:     https://github.com/onezens/YCDownloadSession
//

#import <UIKit/UIKit.h>
@class YCDownloadTask;

typedef void (^YCCompletionHanlder)(NSString *localPath, NSError *error);
typedef void (^YCProgressHanlder)(NSProgress *progress, YCDownloadTask *task);

/**某一任务下载的状态发生变化的通知*/
extern NSString * const kDownloadStatusChangedNoti;
extern NSString * const kDownloadTaskEntityName;

#pragma mark - YCDownloadTask

@interface YCDownloadTask : NSObject

@property (nonatomic, copy, readonly) NSString *taskId;
@property (nonatomic, copy, readonly) NSString *downloadURL;
@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, assign, readonly) NSInteger fileSize;
@property (nonatomic, assign) NSInteger downloadedSize;
/**重新创建下载session，恢复下载状态的session的标识*/
@property (nonatomic, assign) BOOL needToRestart;
/**
 是否支持断点续传
 */
@property (nonatomic, assign, readonly) BOOL isSupportRange;
/**
 是否 不需要下载下一个任务的标识，用来区分全部暂停和单个任务暂停后的操作
 */
@property (nonatomic, assign) BOOL noNeedToStartNext;
@property (nonatomic, copy) NSString *tmpName;
@property (nonatomic, copy) NSString *tempPath;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, copy) NSString *compatibleKey;
@property (nonatomic, strong, readonly) NSProgress *progress;
@property (nonatomic, assign) NSInteger stid;
/**
 default value: NSURLSessionTaskPriorityDefault
 option: NSURLSessionTaskPriorityDefault NSURLSessionTaskPriorityLow NSURLSessionTaskPriorityHigh
 poiority float value range: 0.0 - 1.0
 */
@property (nonatomic, assign, readonly) float priority;

/**
 enable calculate download task speed
 default value: false
 */
@property (nonatomic, assign) BOOL enableSpeed;

@property (nonatomic, copy) YCCompletionHanlder completionHanlder;
@property (nonatomic, copy) YCProgressHanlder progressHandler;

#pragma mark - method

+ (instancetype)taskWithRequest:(NSURLRequest *)request progress:(YCProgressHanlder)progress completion:(YCCompletionHanlder)completion;

+ (instancetype)taskWithRequest:(NSURLRequest *)request progress:(YCProgressHanlder)progress completion:(YCCompletionHanlder)completion priority:(float)priority;

/**
 下载进度第一次回调调用，保存文件大小信息
 */
- (void)updateTask;

/**
 download progress use calculate task speed
 */
- (void)downloadedSize:(NSUInteger)downloadedSize fileSize:(NSUInteger)fileSize;



@end


#pragma mark - YCResumeData
@interface YCResumeData: NSObject

@property (nonatomic, copy) NSString *downloadUrl;
@property (nonatomic, strong) NSMutableURLRequest *currentRequest;
@property (nonatomic, strong) NSMutableURLRequest *originalRequest;
@property (nonatomic, assign) NSInteger downloadSize;
@property (nonatomic, copy) NSString *resumeTag;
@property (nonatomic, assign) NSInteger resumeInfoVersion;
@property (nonatomic, strong) NSDate *downloadDate;
@property (nonatomic, copy) NSString *tempName;
@property (nonatomic, copy) NSString *resumeRange;

- (instancetype)initWithResumeData:(NSData *)resumeData;

+ (NSURLSessionDownloadTask *)downloadTaskWithCorrectResumeData:(NSData *)resumeData urlSession:(NSURLSession *)urlSession;

/**
 清除 NSURLSessionResumeByteRange 字段
 修正iOS11.0 iOS11.1 多次暂停继续 文件大小不对的问题(iOS11.2官方已经修复)
 
 @param resumeData 原始resumeData
 @return 清除后resumeData
 */
+ (NSData *)cleanResumeData:(NSData *)resumeData;
@end

