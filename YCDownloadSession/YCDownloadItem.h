//
//  YCDownloadItem.h
//  YCDownloadSession
//
//  Created by wz on 17/7/28.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Contact me: http://www.onezen.cc/about/
//  Github:     https://github.com/onezens/YCDownloadSession
//

#import <Foundation/Foundation.h>
#import "YCDownloadTask.h"
@class YCDownloadItem;

extern NSString * const kDownloadTaskFinishedNoti;

typedef NS_ENUM(NSUInteger, YCDownloadStatus) {
    YCDownloadStatusUnknow,
    YCDownloadStatusWaiting,
    YCDownloadStatusDownloading,
    YCDownloadStatusPaused,
    YCDownloadStatusFailed,
    YCDownloadStatusFinished
};

@protocol YCDownloadItemDelegate <NSObject>

@optional
- (void)downloadItemStatusChanged:(nonnull YCDownloadItem *)item;
- (void)downloadItem:(nonnull YCDownloadItem *)item downloadedSize:(int64_t)downloadedSize totalSize:(int64_t)totalSize;
- (void)downloadItem:(nonnull YCDownloadItem *)item speed:(NSUInteger)speed speedDesc:(NSString *)speedDesc;
@end

@interface YCDownloadItem : NSObject

-(nonnull instancetype)initWithUrl:(nonnull NSString *)url fileId:(nullable NSString *)fileId;
+(nonnull instancetype)itemWithUrl:(nonnull NSString *)url fileId:(nullable NSString *)fileId;

@property (nonatomic, copy, nonnull) NSString *taskId;
@property (nonatomic, copy, readonly, nullable) NSString *fileId;
@property (nonatomic, copy, readonly, nonnull) NSString *downloadURL;
@property (nonatomic, copy, readonly, nonnull) NSString *version;
@property (nonatomic, assign, readonly) int64_t fileSize;
@property (nonatomic, assign, readonly) int64_t downloadedSize;
@property (nonatomic, weak, nullable) id <YCDownloadItemDelegate> delegate;
@property (nonatomic, assign) BOOL enableSpeed;
@property (nonatomic, strong, nullable) NSData *extraData;
@property (nonatomic, assign, readwrite) YCDownloadStatus downloadStatus;
@property (nonatomic, copy, readonly, nullable) YCProgressHandler progressHandler;
@property (nonatomic, copy, readonly, nullable) YCCompletionHandler completionHandler;
/**
 下载的文件在沙盒保存的类型，默认为video.可指定为pdf，image，等自定义类型
 */
@property (nonatomic, copy, nullable) NSString *fileType;
@property (nonatomic, copy, nullable) NSString *uid;
@property (nonatomic, copy, nonnull) NSString *saveRootPath;
/**文件沙盒保存路径*/
@property (nonatomic, copy, readonly, nonnull) NSString *savePath;

@end

