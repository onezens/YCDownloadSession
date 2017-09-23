//
//  YCDownloadTask.h
//  YCDownloadSession
//
//  Created by wz on 17/3/15.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const kYCDownloadSessionSaveDownloadStatus = @"kYCDownloadSessionSaveDownloadStatus";

@class YCDownloadTask;
@protocol YCDownloadTaskDelegate <NSObject>

@optional
- (void)downloadProgress:(YCDownloadTask *)task totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
- (void)downloadFailed:(YCDownloadTask *)task;
- (void)downloadFinished:(YCDownloadTask *)task;
- (void)downloadCreated:(YCDownloadTask *)task;
- (void)downloadPaused:(YCDownloadTask *)task;

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

@property (nonatomic, assign, readonly) NSInteger fileSize;



+ (NSString *)getURLFromTask:(NSURLSessionTask *)task;

- (void)updateTask;

+ (NSString *)savePathWithSaveName:(NSString *)saveName;

+ (NSString *)saveDir;


@end
