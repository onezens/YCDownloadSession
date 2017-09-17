//
//  YCDownloadTask.h
//  YCDownloadSession
//
//  Created by wz on 17/3/15.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YCDownloadTask;
@protocol YCDownloadSessionDelegate <NSObject>

@optional
- (void)downloadProgress:(YCDownloadTask *)task totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
- (void)downloadFailed:(YCDownloadTask *)task;
- (void)downloadFinished:(YCDownloadTask *)task;
- (void)downloadCreated:(YCDownloadTask *)task;

@end

@interface YCDownloadTask : NSObject

@property (nonatomic, copy) NSString *downloadURL;
@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, assign) NSInteger downloadedSize;
@property (nonatomic, copy, readonly) NSString *saveName;
@property (nonatomic, copy) NSString *tempPath;
@property (nonatomic, weak) id <YCDownloadSessionDelegate>delegate;

@property (nonatomic, assign, readonly) NSInteger fileSize;



+ (NSString *)getURLFromTask:(NSURLSessionTask *)task;

- (void)updateTask;

+ (NSString *)savePathWithSaveName:(NSString *)saveName;

+ (NSString *)saveDir;


@end
