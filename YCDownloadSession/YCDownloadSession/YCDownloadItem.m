//
//  YCDownloadItem.m
//  YCDownloadSession
//
//  Created by wz on 17/7/28.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Contact me: http://www.onezen.cc
//  Github:     https://github.com/onezens/YCDownloadSession
//

#import "YCDownloadItem.h"
#import <objc/runtime.h>
#import "YCDownloadSession.h"
#import "YCDownloadDB.h"

NSString * const kDownloadTaskFinishedNoti = @"kDownloadTaskFinishedNoti";
NSString * const kDownloadNeedSaveDataNoti = @"kDownloadNeedSaveDataNoti";
NSString * const kDownloadItemStoreEntity  = @"YCDownloadItem";

@interface YCDownloadItem()
{
    NSString *_taskId;
    NSString *_fileId;
    NSString *_downloadUrl;
}

@end

@implementation YCDownloadItem

@dynamic fileId;
@dynamic taskId;
@dynamic downloadUrl;
@dynamic fileName;
@dynamic thumbImageUrl;
@dynamic saveFileType;
@dynamic extraData;
@dynamic downloadStatus;
@synthesize delegate = _delegate;
@synthesize enableSpeed = _enableSpeed;
@synthesize progressHanlder = _progressHanlder;
@synthesize completionHanlder = _completionHanlder;
#pragma mark - init


- (instancetype)initWithUrl:(NSString *)url fileId:(NSString *)fileId {
    if (self = [super initWithContext:[YCDownloadDB sharedDB].context]) {
        _downloadUrl = url;
        _fileId = fileId;
        __weak typeof(self) weakSelf = self;
        _progressHanlder = ^(NSProgress *progress){
            if(weakSelf.downloadStatus == YCDownloadStatusWaiting){
                [weakSelf downloadStatusChanged:YCDownloadStatusDownloading downloadTask:nil];
            }
            [weakSelf downloadProgress:nil downloadedSize:progress.completedUnitCount fileSize:progress.totalUnitCount];
        };
        _completionHanlder = ^(NSString *localPath, NSError *error){
            if (error) {
                [weakSelf downloadStatusChanged:YCDownloadStatusFailed downloadTask:nil];
            }else{
                [weakSelf downloadStatusChanged:YCDownloadStatusFinished downloadTask:nil];
            }
            //TODO: saveData
        };
    }
    return self;
}
+ (instancetype)itemWithUrl:(NSString *)url fileId:(NSString *)fileId {
    return [[YCDownloadItem alloc] initWithUrl:url fileId:fileId];
}

#pragma mark - YCDownloadSessionDelegate
- (void)downloadProgress:(YCDownloadTask *)task downloadedSize:(NSUInteger)downloadedSize fileSize:(NSUInteger)fileSize {
    if ([self.delegate respondsToSelector:@selector(downloadItem:downloadedSize:totalSize:)]) {
        [self.delegate downloadItem:self downloadedSize:downloadedSize totalSize:fileSize];
    }
}

- (void)downloadStatusChanged:(YCDownloadStatus)status downloadTask:(YCDownloadTask *)task {
    
    if ([self.delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
        [self.delegate downloadItemStatusChanged:self];
    }
    //通知优先级最后，不与上面的finished重合
    if (status == YCDownloadStatusFinished) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadTaskFinishedNoti object:self];
    }
}

- (void)downloadCreated:(YCDownloadTask *)task {
    [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadNeedSaveDataNoti object:nil userInfo:nil];
}

- (void)downloadTask:(YCDownloadTask *)task speed:(NSUInteger)speed speedDesc:(NSString *)speedDesc {
    if ([self.delegate respondsToSelector:@selector(downloadItem:speed:speedDesc:)]) {
        [self.delegate downloadItem:self speed:speed speedDesc:speedDesc];
    }
}
#pragma mark - public

- (NSString *)compatibleKey {
    return [YCDownloader downloadVersion];
}

- (NSString *)saveName {
    YCDownloadTask *task = nil;//[[YCDownloadSession downloadSession] taskForTaskId:_taskId];
    return task;
}

- (NSString *)savePath {
    return nil;;
}

- (NSUInteger)downloadedSize {
    YCDownloadTask *task = nil; //[[YCDownloadSession downloadSession] taskForTaskId:_taskId];
    return task.downloadedSize;
}

- (YCDownloadStatus)downloadStatus {
    YCDownloadTask *task = nil; //[[YCDownloadSession downloadSession] taskForTaskId:_taskId];
    return task;
}

- (void)setDelegate:(id<YCDownloadItemDelegate>)delegate {
//    _delegate = delegate;
//    YCDownloadTask *task = nil;//[[YCDownloadSession downloadSession] taskForTaskId:_taskId];
//    task.delegate = self;
}

- (NSUInteger)fileSize {
    YCDownloadTask *task = nil;//[[YCDownloadSession downloadSession] taskForTaskId:_taskId];
    return task.fileSize;
}

@end
