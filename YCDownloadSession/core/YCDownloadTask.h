//
//  YCDownloadTask.h
//  YCDownloadSession
//
//  Created by wz on 17/3/15.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Contact me: http://www.onezen.cc/about/
//  Github:     https://github.com/onezens/YCDownloadSession
//

#import <UIKit/UIKit.h>
@class YCDownloadTask;

typedef void (^YCCompletionHandler)(NSString  * _Nullable localPath, NSError * _Nullable error);
typedef void (^YCProgressHandler)(NSProgress * _Nonnull progress,YCDownloadTask * _Nonnull task);

#pragma mark - YCDownloadTask

@interface YCDownloadTask : NSObject

@property (nonatomic, strong, nullable) NSData *resumeData;
@property (nonatomic, copy, readonly, nonnull) NSString *taskId;
@property (nonatomic, copy, readonly, nonnull) NSString *downloadURL;
@property (nonatomic, assign, readonly) int64_t fileSize;
@property (nonatomic, assign) int64_t downloadedSize;
@property (nonatomic, copy, nonnull) NSString *version;
/**
 default value: NSURLSessionTaskPriorityDefault
 option: NSURLSessionTaskPriorityDefault NSURLSessionTaskPriorityLow NSURLSessionTaskPriorityHigh
 poiority float value range: 0.0 - 1.0
 */
@property (nonatomic, assign, readonly) float priority;
@property (nonatomic, assign, readonly) BOOL isRunning;
@property (nonatomic, strong, readonly, nonnull) NSProgress *progress;
@property (nonatomic, copy, nullable) YCProgressHandler progressHandler;
@property (nonatomic, copy, nullable) YCCompletionHandler completionHandler;
@property (nonatomic, strong, nonnull) NSData *extraData;

/**
 if no downloadTask, state = -1
 */
@property (nonatomic, assign, readonly) NSURLSessionTaskState state;

#pragma mark - method
- (void)updateTask;

+ (nonnull instancetype)taskWithRequest:(nonnull NSURLRequest *)request progress:(YCProgressHandler)progress completion:(YCCompletionHandler)completion;

+ (nonnull instancetype)taskWithRequest:(nonnull NSURLRequest *)request progress:(YCProgressHandler)progress completion:(YCCompletionHandler)completion priority:(float)priority;

+ (nonnull NSString *)downloaderVerison;

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

