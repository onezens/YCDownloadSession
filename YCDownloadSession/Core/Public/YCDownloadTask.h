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

@interface YCDownloadTask : NSObject

@property (nonatomic, assign, readonly) YCDownloadTaskState state;

+ (instancetype)taskWithTask:(NSURLSessionDownloadTask *)task;

- (void)pause;

- (void)pauseWithResumeData:(NSData *)data;

- (void)resume;

- (void)resumeWithResumeData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END
