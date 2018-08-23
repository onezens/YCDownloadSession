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

extern NSString * const kDownloadTaskFinishedNoti;
extern NSString * const kDownloadNeedSaveDataNoti;
extern NSString * const kDownloadItemStoreEntity;

@protocol YCDownloadItemDelegate <NSObject>

@optional
- (void)downloadItemStatusChanged:(YCDownloadItem *)item;
- (void)downloadItem:(YCDownloadItem *)item downloadedSize:(int64_t)downloadedSize totalSize:(int64_t)totalSize;
- (void)downloadItem:(YCDownloadItem *)item speed:(NSUInteger)speed speedDesc:(NSString *)speedDesc;
@end

@interface YCDownloadItem : NSManagedObject <YCDownloadTaskDelegate>

-(instancetype)initWithUrl:(NSString *)url fileId:(NSString *)fileId;
+(instancetype)itemWithUrl:(NSString *)url fileId:(NSString *)fileId;

@property (nonatomic, copy, readonly) NSString *fileId;
@property (nonatomic, copy, readonly) NSString *taskId;
@property (nonatomic, copy, readonly) NSString *savePath;
@property (nonatomic, copy, readonly) NSString *saveName;
@property (nonatomic, copy, readonly) NSString *downloadUrl;
@property (nonatomic, copy, readonly) NSString *compatibleKey;
@property (nonatomic, assign, readonly) NSUInteger fileSize;
@property (nonatomic, assign, readonly) NSUInteger downloadedSize;
@property (nonatomic, assign, readonly) YCDownloadStatus downloadStatus;
@property (nonatomic, weak) id <YCDownloadItemDelegate> delegate;
@property (nonatomic, assign) BOOL enableSpeed;

@property (nonatomic, copy) NSString *fileName;
@property (nonatomic, copy) NSString *thumbImageUrl;
@property (nonatomic, strong) NSData *extraData;

/**
 下载的文件在沙盒保存的类型，默认为video.可指定为pdf，image，等自定义类型
 */
@property (nonatomic, copy) NSString *saveFileType;

@end


