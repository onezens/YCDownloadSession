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

NSString * const kDownloadTaskFinishedNoti = @"kDownloadTaskFinishedNoti";
NSString * const kDownloadNeedSaveDataNoti = @"kDownloadNeedSaveDataNoti";

@implementation YCDownloadItem

#pragma mark - init
-(instancetype)initWithUrl:(NSString *)url fileId:(NSString *)fileId {
    
    if (self = [super init]) {
        _downloadUrl = url;
        _fileId = fileId;
        _taskId = [YCDownloadTask taskIdForUrl:url fileId:fileId];
        _compatibleKey = [YCDownloadSession downloadSession].downloadVersion;
    }
    return self;
}
+(instancetype)itemWithUrl:(NSString *)url fileId:(NSString *)fileId {
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

- (NSString *)saveName {
    YCDownloadTask *task = [[YCDownloadSession downloadSession] taskForTaskId:_taskId];
    return task.saveName;
}

- (NSString *)savePath {
    return [YCDownloadTask savePathWithSaveName:self.saveName];
}

- (NSUInteger)downloadedSize {
    YCDownloadTask *task = [[YCDownloadSession downloadSession] taskForTaskId:_taskId];
    return task.downloadedSize;
}

- (YCDownloadStatus)downloadStatus {
    YCDownloadTask *task = [[YCDownloadSession downloadSession] taskForTaskId:_taskId];
    return task.downloadStatus;
}

- (void)setDelegate:(id<YCDownloadItemDelegate>)delegate {
    _delegate = delegate;
    YCDownloadTask *task = [[YCDownloadSession downloadSession] taskForTaskId:_taskId];
    task.delegate = self;
}

- (NSUInteger)fileSize {
    YCDownloadTask *task = [[YCDownloadSession downloadSession] taskForTaskId:_taskId];
    return task.fileSize;
}

#pragma mark - private

///  解档
- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super init]) {
        
        [self decoderWithCoder:coder class:[self class]];
        if (![NSStringFromClass(self.superclass) isEqualToString:NSStringFromClass([NSObject class])]) {
            [self decoderWithCoder:coder class:self.superclass];
        }
    }
    return self;
}

- (void)decoderWithCoder:(NSCoder *)coder class:(Class)cls {
    unsigned int count = 0;
    
    Ivar *ivars = class_copyIvarList(cls, &count);
    
    for (NSInteger i=0; i<count; i++) {
        
        Ivar ivar = ivars[i];
        NSString *name = [[NSString alloc] initWithUTF8String:ivar_getName(ivar)];
        if([name isEqualToString:@"_delegate"]) continue;
        id value = [coder decodeObjectForKey:name];
        if(value) [self setValue:value forKey:name];
    }
    
    free(ivars);
}


///  归档
- (void)encodeWithCoder:(NSCoder *)coder
{
    [self encodeWithCoder:coder class:[self class]];
    if (![NSStringFromClass(self.superclass) isEqualToString:NSStringFromClass([NSObject class])]) {
        [self encodeWithCoder:coder class:self.superclass];
    }
}

- (void)encodeWithCoder:(NSCoder *)coder class:(Class)cls {
    unsigned int count = 0;
    
    Ivar *ivars = class_copyIvarList(cls, &count);
    
    for (NSInteger i=0; i<count; i++) {
        
        Ivar ivar = ivars[i];
        NSString *name = [[NSString alloc] initWithUTF8String:ivar_getName(ivar)];
        if([name isEqualToString:@"_delegate"]) continue;
        id value = [self valueForKey:name];
        if(value) [coder encodeObject:value forKey:name];
    }
    
    free(ivars);
}


@end
