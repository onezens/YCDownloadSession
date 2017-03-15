//
//  YCDownloadSession.h
//  YCDownloadSession
//
//  Created by wangzhen on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YCDownloadItem.h"

@class YCDownloadSession;
@protocol YCDownloadSessionDelegate <NSObject>

- (void)request:(YCDownloadSession *)request totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
- (void)requestFailed:(YCDownloadSession *)request;
- (void)requestFinished:(YCDownloadSession *)request;

@end

@interface YCDownloadSession : NSObject

@property (nonatomic, weak) id <YCDownloadSessionDelegate>delegate;

@property (nonatomic, copy) NSString *saveFileDirectory;

+ (instancetype)downloadSession;

/**
 开始一个后台下载任务

 @param downloadURLString 下载url
 */
- (void)startDownloadWithUrl:(NSString *)downloadURLString;

/**
 暂停一个后台下载任务

 @param downloadURLString 下载url
 */
- (void)pauseDownloadWithUrl:(NSString *)downloadURLString;

/**
 继续开始一个后台下载任务

 @param downloadURLString 下载url
 */
- (void)resumeDownloadWithUrl:(NSString *)downloadURLString;

/**
 删除一个后台下载任务，同时会删除当前任务下载的缓存数据

 @param downloadURLString 下载url
 */
- (void)stopDownloadWithUrl:(NSString *)downloadURLString;

@end
