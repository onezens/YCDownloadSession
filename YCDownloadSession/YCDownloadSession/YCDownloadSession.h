//
//  YCDownloadSession.h
//  YCDownloadSession
//
//  Created by wangzhen on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import <Foundation/Foundation.h>
@class YCDownloadSession;
@protocol YCDownloadSessionDelegate <NSObject>

- (void)request:(YCDownloadSession *)request totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
- (void)requestFailed:(YCDownloadSession *)request;
- (void)requestFinished:(YCDownloadSession *)request;

@end

@interface YCDownloadSession : NSObject

@property (nonatomic, weak) id <YCDownloadSessionDelegate>delegate;

@property (nonatomic, copy) NSString *savePath;

+ (instancetype)downloadSession;

- (void)startDownloadWithUrl:(NSString *)downloadURLString;
- (void)pauseDownloadWithUrl:(NSString *)downloadURLString;
- (void)resumeDownloadWithUrl:(NSString *)downloadURLString;
- (void)stopDownloadWithUrl:(NSString *)downloadURLString;

@end
