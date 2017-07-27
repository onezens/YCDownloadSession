//
//  YCDownloadItem.h
//  YCDownloadSession
//
//  Created by wangzhen on 17/3/15.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class YCDownloadItem;
@protocol YCDownloadSessionDelegate <NSObject>

@optional
- (void)downloadProgress:(YCDownloadItem *)downloadItem totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
- (void)downloadFailed:(YCDownloadItem *)downloadItem;
- (void)downloadinished:(YCDownloadItem *)downloadItem;

@end

@interface YCDownloadItem : NSObject

@property (nonatomic, copy) NSString *downloadURL;
@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, assign) NSInteger downloadedSize;
@property (nonatomic, copy, readonly) NSString *saveName;
@property (nonatomic, copy) NSString *tempPath;
@property (nonatomic, weak) id <YCDownloadSessionDelegate>delegate;

@property (nonatomic, assign, readonly) NSInteger fileSize;



+ (NSString *)getURLFromTask:(NSURLSessionTask *)task;

- (void)updateItem;

+ (NSString *)savePathWithSaveName:(NSString *)saveName;


@end
