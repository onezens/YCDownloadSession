//
//  YCDownloadTask.h
//  YCDownloadSession-library
//
//  Created by wz on 2022/2/25.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, YCDownloadTaskState) {
    YCDownloadTaskStatePending      = 0,
    YCDownloadTaskStateRunning      = 1,
    YCDownloadTaskStateSuspended    = 2,
    YCDownloadTaskStateCompleted    = 3,
};

NS_ASSUME_NONNULL_BEGIN

typedef void (^YCDownloadCompletionBlock)(NSURL * _Nullable fileURL, NSError * _Nullable error);

@interface YCDownloadTask : NSObject

@property (nonatomic, assign, readonly) YCDownloadTaskState state;

@property (nonatomic, copy, nullable) void (^progressBlock) (float progress);

@property (nonatomic, copy, nullable) YCDownloadCompletionBlock completionBlock;

- (void)pause;

- (void)pauseWithResumeData:(void (NS_SWIFT_SENDABLE ^)(NSData * _Nullable resumeData))completionHandler;

- (void)resume;

- (void)resumeWithResumeData:(NSData * _Nullable)resumeData;

- (void)resumeWithResumeData:(NSData * _Nullable)resumeData
                  completion:(YCDownloadCompletionBlock _Nullable)completionBlock;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
