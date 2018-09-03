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

NSString * const kDownloadTaskFinishedNoti = @"kDownloadTaskFinishedNoti";
NSString * const kDownloadNeedSaveDataNoti = @"kDownloadNeedSaveDataNoti";

@interface YCDownloadItem()
@property (nonatomic, copy) NSString *fileExtension;
@property (nonatomic, copy) NSString *rootPath;
@end

@implementation YCDownloadItem
#pragma mark - init

- (instancetype)initWithUrl:(NSString *)url fileId:(NSString *)fileId {
    if (self) {
        [self setValue:url forKey:@"downloadUrl"];
        [self setValue:fileId forKey:@"fileId"];
    }
    return self;
}
+ (instancetype)itemWithUrl:(NSString *)url fileId:(NSString *)fileId {
    return [[YCDownloadItem alloc] initWithUrl:url fileId:fileId];
}

#pragma mark - YCDownloadSessionDelegate
- (void)downloadProgress:(YCDownloadTask *)task downloadedSize:(NSUInteger)downloadedSize fileSize:(NSUInteger)fileSize {
    if (self.fileSize==0)  [self setValue:@(fileSize) forKey:@"fileSize"];
    if (!self.fileExtension) [self setFileExtensionWithTask:task];
    [self setValue:@(downloadedSize) forKey:@"downloadedSize"];
    if ([self.delegate respondsToSelector:@selector(downloadItem:downloadedSize:totalSize:)]) {
        [self.delegate downloadItem:self downloadedSize:downloadedSize totalSize:fileSize];
    }
}

- (void)downloadStatusChanged:(YCDownloadStatus)status downloadTask:(YCDownloadTask *)task {
    [self setValue:@(status) forKey:@"downloadStatus"];
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

#pragma mark - getter & setter

- (void)setSaveRootPath:(NSString *)saveRootPath {
    NSString *path = [saveRootPath stringByReplacingOccurrencesOfString:NSHomeDirectory() withString:@""];
    [self setValue:path forKey:@"rootPath"];
}

- (NSString *)saveRootPath {
    NSString *rootPath = self.rootPath;
    if(!rootPath){
        rootPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true).firstObject;
        rootPath = [rootPath stringByAppendingPathComponent:@"YCDownload"];
    }else{
        rootPath = [NSHomeDirectory() stringByAppendingPathComponent:rootPath];
    }
    return rootPath;
}

- (void)setFileExtensionWithTask:(YCDownloadTask *)task {
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.downloadTask.response;
    NSAssert([response isKindOfClass:[NSHTTPURLResponse class]], @"response can not nil & class must be NSHTTPURLResponse");
    NSString *extension = response.suggestedFilename.pathExtension;
    if(!extension) extension = [[response.allHeaderFields valueForKey:@"Content-Type"] componentsSeparatedByString:@"/"].lastObject;
    if(!extension) extension = @"data";
    [self setValue:extension forKey:@"fileExtension"];
}

- (YCProgressHanlder)progressHanlder {
    __weak typeof(self) weakSelf = self;
    return ^(NSProgress *progress, YCDownloadTask *task){
        if(weakSelf.downloadStatus == YCDownloadStatusWaiting){
            [weakSelf downloadStatusChanged:YCDownloadStatusDownloading downloadTask:nil];
        }
        [weakSelf downloadProgress:task downloadedSize:progress.completedUnitCount fileSize:progress.totalUnitCount];
    };
}

- (YCCompletionHanlder)completionHanlder {
    __weak typeof(self) weakSelf = self;
    return ^(NSString *localPath, NSError *error){
        NSError *saveError = nil;
        if([[NSFileManager defaultManager] fileExistsAtPath:self.savePath]){
            NSLog(@"[Item completionHanlder] Warning file Exist at path: %@ and replaced it!", self.savePath);
            [[NSFileManager defaultManager] removeItemAtPath:self.savePath error:nil];
        }
        if (error) {
            [weakSelf downloadStatusChanged:YCDownloadStatusFailed downloadTask:nil];
        }else if([[NSFileManager defaultManager] moveItemAtPath:localPath toPath:self.savePath error:&saveError]){
            [weakSelf downloadStatusChanged:YCDownloadStatusFinished downloadTask:nil];
        }else{
            [weakSelf downloadStatusChanged:YCDownloadStatusFailed downloadTask:nil];
            NSLog(@"[Item completionHanlder] move file failed error: %@ \nlocalPath: %@ \nsavePath:%@", saveError,localPath,self.savePath);
        }
        [YCDownloadDB saveItem:self];
    };
}

#pragma mark - public

- (NSString *)compatibleKey {
    return [YCDownloader downloadVersion];
}

- (NSString *)saveDirectory {
    NSString *path = [self saveRootPath];
    path = [path stringByAppendingFormat:@"/%@/%@", (self.uid ? self.uid : @"YCDownloadUID"), (self.fileType ? self.fileType : @"data")];
    [YCDownloadUtils createPathIfNotExist:path];
    return path;
}

- (NSString *)saveName {
    NSString *saveName = self.fileId ? self.fileId : self.taskId;
    return [saveName stringByAppendingPathExtension: self.fileExtension ? : @"data"];
}

- (NSString *)savePath {
    return [[self saveDirectory] stringByAppendingPathComponent:[self saveName]];
}
@end
