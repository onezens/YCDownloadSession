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
extern NSString * const kDownloadTaskAllFinishedNoti;

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
- (void)downloadItemStatusChanged:(YCDownloadItem *)item;
- (void)downloadItem:(YCDownloadItem *)item downloadedSize:(int64_t)downloadedSize totalSize:(int64_t)totalSize;
- (void)downloadItem:(YCDownloadItem *)item speed:(NSUInteger)speed speedDesc:(NSString *)speedDesc;
@end

@interface YCDownloadItem : NSObject

-(instancetype)initWithUrl:(NSString *)url fileId:(NSString *)fileId;
+(instancetype)itemWithUrl:(NSString *)url fileId:(NSString *)fileId;

@property (nonatomic, copy) NSString *taskId;
@property (nonatomic, copy, readonly) NSString *fileId;
@property (nonatomic, copy, readonly) NSString *downloadURL;
@property (nonatomic, copy, readonly) NSString *version;
@property (nonatomic, assign, readonly) NSUInteger fileSize;
@property (nonatomic, assign, readonly) NSUInteger downloadedSize;
@property (nonatomic, weak) id <YCDownloadItemDelegate> delegate;
@property (nonatomic, assign) BOOL enableSpeed;
@property (nonatomic, strong) NSData *extraData;
@property (nonatomic, assign, readwrite) YCDownloadStatus downloadStatus;
@property (nonatomic, copy, readonly) YCProgressHanlder progressHanlder;
@property (nonatomic, copy, readonly) YCCompletionHanlder completionHanlder;
/**
 下载的文件在沙盒保存的类型，默认为video.可指定为pdf，image，等自定义类型
 */
@property (nonatomic, copy) NSString *fileType;
@property (nonatomic, copy) NSString *uid;
@property (nonatomic, copy) NSString *saveRootPath;
/**文件沙盒保存路径*/
@property (nonatomic, copy, readonly) NSString *savePath;


@end


