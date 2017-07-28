//
//  YCDownloadSession.h
//  YCDownloadSession
//
//  Created by wangzhen on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YCDownloadItem.h"

@class YCDownloadSession;

@interface YCDownloadSession : NSObject

@property (nonatomic, copy) NSString *saveFilePath;

@property (nonatomic, strong, readonly) NSURLSession *downloadSession;


+ (instancetype)downloadSession;

- (void)changeStatusIsAllowCellar:(BOOL)isAllow;


/**
 开始一个后台下载任务
 
 @param downloadURLString 下载url
 */
- (void)startDownloadWithUrl:(NSString *)downloadURLString delegate:(id<YCDownloadSessionDelegate>)delegate;

/**
 暂停一个后台下载任务
 
 @param downloadURLString 下载url
 */
- (void)pauseDownloadWithUrl:(NSString *)downloadURLString;

/**
 继续开始一个后台下载任务
 
 @param downloadURLString 下载url
 */
- (void)resumeDownloadWithUrl:(NSString *)downloadURLString delegate:(id<YCDownloadSessionDelegate>)delegate;

/**
 删除一个后台下载任务，同时会删除当前任务下载的缓存数据
 
 @param downloadURLString 下载url
 */
- (void)stopDownloadWithUrl:(NSString *)downloadURLString;


/**
 保存下载进度
 */
- (void)saveDownloadStatus;

/**
 暂停所有的下载
 */
- (void)pauseAllDownloadTask;




@end
