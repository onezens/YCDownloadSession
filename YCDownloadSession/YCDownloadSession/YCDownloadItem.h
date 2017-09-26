//
//  YCDownloadItem.h
//  YCDownloadSession
//
//  Created by wz on 17/7/28.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Github: https://github.com/onezens/YCDownloadSession
//

#import <Foundation/Foundation.h>
#import "YCDownloadTask.h"
@class YCDownloadItem;
/**某一的任务下载完成的通知*/
static NSString * const kDownloadTaskFinishedNoti = @"kDownloadTaskFinishedNoti";

@protocol YCDownloadItemDelegate <NSObject>

@optional
- (void)downloadItemStatusChanged:(YCDownloadItem *)item;
- (void)downloadItem:(YCDownloadItem *)item downloadedSize:(int64_t)downloadedSize totalSize:(int64_t)totalSize;

@end

@interface YCDownloadItem : NSObject<YCDownloadTaskDelegate>

@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *thumbImageUrl;
@property (nonatomic, copy) NSString *downloadUrl;
@property (nonatomic, assign) NSUInteger fileSize;
@property (nonatomic, assign) NSUInteger downloadedSize;
@property (nonatomic, assign) YCDownloadStatus downloadStatus;
@property (nonatomic, copy, readonly) NSString *saveName;
@property (nonatomic, weak) id <YCDownloadItemDelegate> delegate;

- (NSString *)savePath;

@end


