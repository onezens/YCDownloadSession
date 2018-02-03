//
//  YCDownloadItem.h
//  YCDownloadSession
//
//  Created by wz on 17/7/28.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Contact me: http://www.onezen.cc
//  Github:     https://github.com/onezens/YCDownloadSession
//

#import <Foundation/Foundation.h>
#import "YCDownloadTask.h"
@class YCDownloadItem;

/**某一的任务下载完成的通知*/
static NSString * const kDownloadTaskFinishedNoti = @"kDownloadTaskFinishedNoti";
/**保存下载数据通知*/
static NSString * const kDownloadNeedSaveDataNoti = @"kDownloadNeedSaveDataNoti";

@protocol YCDownloadItemDelegate <NSObject>

@optional
- (void)downloadItemStatusChanged:(YCDownloadItem *)item;
- (void)downloadItem:(YCDownloadItem *)item downloadedSize:(int64_t)downloadedSize totalSize:(int64_t)totalSize;

@end

@interface YCDownloadItem : NSObject<YCDownloadTaskDelegate>

-(instancetype)initWithUrl:(NSString *)url fileId:(NSString *)fileId;
+(instancetype)itemWithUrl:(NSString *)url fileId:(NSString *)fileId;

/**下载任务标识*/
@property (nonatomic, copy,readonly) NSString *fileId;
@property (nonatomic, copy,readonly) NSString *downloadUrl;
@property (nonatomic, copy, readonly) NSString *taskId;
@property (nonatomic, weak) id <YCDownloadItemDelegate> delegate;
@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *thumbImageUrl;
/**下载完成后保存在本地的路径*/
@property (nonatomic, readonly) NSString *savePath;
@property (nonatomic, assign) NSUInteger fileSize;
@property (nonatomic, assign) NSUInteger downloadedSize;
@property (nonatomic, assign) YCDownloadStatus downloadStatus;
@property (nonatomic, copy, readonly) NSString *saveName;
@property (nonatomic, copy) NSString *compatibleKey;


@end


