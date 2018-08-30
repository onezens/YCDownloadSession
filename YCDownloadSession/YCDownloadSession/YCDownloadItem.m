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
#import "YCDownloadSession.h"
#import "YCDownloadDB.h"

NSString * const kDownloadTaskFinishedNoti = @"kDownloadTaskFinishedNoti";
NSString * const kDownloadNeedSaveDataNoti = @"kDownloadNeedSaveDataNoti";
NSString * const kDownloadItemStoreEntity  = @"YCDownloadItem";

@interface YCDownloadItem()

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
@dynamic downloadedSize;
@dynamic fileSize;

@synthesize delegate = _delegate;
@synthesize enableSpeed = _enableSpeed;
@synthesize progressHanlder = _progressHanlder;
@synthesize completionHanlder = _completionHanlder;
#pragma mark - init


- (instancetype)initWithUrl:(NSString *)url fileId:(NSString *)fileId {
    if (self = [super initWithContext:[YCDownloadDB sharedDB].context]) {
        [self setValue:url forKey:@"downloadUrl"];
        [self setValue:fileId forKey:@"fileId"];
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
    if (self.fileSize==0)  [self setValue:@(fileSize) forKey:@"fileSize"];
    [self setValue:@(downloadedSize) forKey:@"downloadedSize"];
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

@end
