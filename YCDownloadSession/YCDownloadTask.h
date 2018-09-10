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

typedef void (^YCCompletionHanlder)(NSString *localPath, NSError *error);
typedef void (^YCProgressHanlder)(NSProgress *progress, YCDownloadTask *task);

#pragma mark - YCDownloadTask

@interface YCDownloadTask : NSObject

@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, copy, readonly) NSString *taskId;
@property (nonatomic, copy, readonly) NSString *downloadURL;
@property (nonatomic, assign, readonly) NSUInteger fileSize;
@property (nonatomic, assign) NSUInteger downloadedSize;
@property (nonatomic, copy) NSString *version;
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
@property (nonatomic, assign, readonly) BOOL isRunning;
@property (nonatomic, strong, readonly) NSProgress *progress;
@property (nonatomic, copy) YCProgressHanlder progressHandler;
@property (nonatomic, copy) YCCompletionHanlder completionHanlder;
@property (nonatomic, strong) NSData *extraData;

#pragma mark - method
- (void)updateTask;

+ (instancetype)taskWithRequest:(NSURLRequest *)request progress:(YCProgressHanlder)progress completion:(YCCompletionHanlder)completion;

+ (instancetype)taskWithRequest:(NSURLRequest *)request progress:(YCProgressHanlder)progress completion:(YCCompletionHanlder)completion priority:(float)priority;

+ (NSString *)downloaderVerison;

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

