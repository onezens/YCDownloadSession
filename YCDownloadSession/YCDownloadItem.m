//
//  YCDownloadItem.m
//  YCDownloadSession
//
//  Created by wz on 17/7/28.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Contact me: http://www.onezen.cc/about/
//  Github:     https://github.com/onezens/YCDownloadSession
//

#import "YCDownloadItem.h"
#import "YCDownloadUtils.h"
#import "YCDownloadDB.h"

NSString * const kDownloadTaskFinishedNoti = @"kDownloadTaskFinishedNoti";

@interface YCDownloadTask(Downloader)
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@end

@interface YCDownloadItem()
@property (nonatomic, copy) NSString *rootPath;
@property (nonatomic, assign) NSInteger pid;
@property (nonatomic, assign) BOOL isRemoved;
@property (nonatomic, assign) BOOL noNeedStartNext;
@property (nonatomic, copy) NSString *fileExtension;
@property (nonatomic, assign, readonly) NSUInteger createTime;
@property (nonatomic, assign) uint64_t preDSize;
@property (nonatomic, strong) NSTimer *speedTimer;
@end

@implementation YCDownloadItem

#pragma mark - init

- (instancetype)initWithPrivate{
    if (self = [super init]) {
        _createTime = [YCDownloadUtils sec_timestamp];
        _version = [YCDownloadTask downloaderVerison];
    }
    return self;
}

- (instancetype)initWithUrl:(NSString *)url fileId:(NSString *)fileId {
    if (self = [self initWithPrivate]) {
        _downloadURL = url;
        _fileId = fileId;
    }
    return self;
}
+ (instancetype)itemWithDict:(NSDictionary *)dict {
    YCDownloadItem *item = [[YCDownloadItem alloc] initWithPrivate];
    [item setValuesForKeysWithDictionary:dict];
    return item;
}
+ (instancetype)itemWithUrl:(NSString *)url fileId:(NSString *)fileId {
    return [[YCDownloadItem alloc] initWithUrl:url fileId:fileId];
}

#pragma mark - Handler
- (void)downloadProgress:(YCDownloadTask *)task downloadedSize:(int64_t)downloadedSize fileSize:(int64_t)fileSize {
    if (self.fileSize==0)  _fileSize = fileSize;
    if (!self.fileExtension) [self setFileExtensionWithTask:task];
    _downloadedSize = downloadedSize;
    if ([self.delegate respondsToSelector:@selector(downloadItem:downloadedSize:totalSize:)]) {
        [self.delegate downloadItem:self downloadedSize:downloadedSize totalSize:fileSize];
    }
}

- (void)downloadStatusChanged:(YCDownloadStatus)status downloadTask:(YCDownloadTask *)task {
    _downloadStatus = status;
    if ([self.delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
        [self.delegate downloadItemStatusChanged:self];
    }
    //通知优先级最后，不与上面的finished重合
    if (status == YCDownloadStatusFinished || status == YCDownloadStatusFailed) {
        [YCDownloadDB saveItem:self];
        [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadTaskFinishedNoti object:self];
    }
    [self calculaterSpeedWithStatus:status];
}

- (void)speedTimerRun {
    uint64_t size = self.downloadedSize> self.preDSize ? self.downloadedSize - self.preDSize : 0;
    if (size == 0) {
        [self.delegate downloadItem:self speed:0 speedDesc:@"0KB/s"];
    }else{
        NSString *ss = [NSString stringWithFormat:@"%@/s",[YCDownloadUtils fileSizeStringFromBytes:size]];
        [self.delegate downloadItem:self speed:size speedDesc:ss];
    }
    self.preDSize = self.downloadedSize;
    //NSLog(@"[speedTimerRun] %@ dsize: %llu pdsize: %llu", ss, self.downloadedSize, self.preDownloadedSize);
}

- (void)invalidateSpeedTimer {
    [self.speedTimer invalidate];
    self.speedTimer = nil;
}

- (void)calculaterSpeedWithStatus:(YCDownloadStatus)status {
    //计算下载速度
    if (!self.enableSpeed) return;
    if (status != YCDownloadStatusDownloading) {
        [self invalidateSpeedTimer];
        [self.delegate downloadItem:self speed:0 speedDesc:@"0KB/s"];
    }else{
        [self.speedTimer fire];
    }
}

#pragma mark - getter & setter

- (void)setDownloadStatus:(YCDownloadStatus)downloadStatus {
    _downloadStatus = downloadStatus;
    if ([self.delegate respondsToSelector:@selector(downloadItemStatusChanged:)]) {
        [self.delegate downloadItemStatusChanged:self];
    }
    [self calculaterSpeedWithStatus:downloadStatus];
}

- (void)setSaveRootPath:(NSString *)saveRootPath {
    NSString *path = [saveRootPath stringByReplacingOccurrencesOfString:NSHomeDirectory() withString:@""];
    _rootPath = path;
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
    NSURLResponse *oriResponse =task.downloadTask.response;
    if ([oriResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)oriResponse;
        NSString *extension = [[response.allHeaderFields valueForKey:@"Content-Type"] componentsSeparatedByString:@"/"].lastObject;
        if ([extension containsString:@";"]) {
            extension = [extension componentsSeparatedByString:@";"].firstObject;
        }
        if(extension.length==0) extension = response.suggestedFilename.pathExtension;
        _fileExtension = extension;
    }else{
        NSLog(@"[warning] downloadTask response class type error: %@", oriResponse);
    }
}

- (YCProgressHandler)progressHandler {
    __weak typeof(self) weakSelf = self;
    return ^(NSProgress *progress, YCDownloadTask *task){
        if(weakSelf.downloadStatus == YCDownloadStatusWaiting){
            [weakSelf downloadStatusChanged:YCDownloadStatusDownloading downloadTask:nil];
        }
        [weakSelf downloadProgress:task downloadedSize:progress.completedUnitCount fileSize:(progress.totalUnitCount>0 ? progress.totalUnitCount : 0)];
    };
}

- (YCCompletionHandler)completionHandler {
    __weak typeof(self) weakSelf = self;
    return ^(NSString *localPath, NSError *error){
        YCDownloadTask *task = [YCDownloadDB taskWithTid:self.taskId];
        if (error) {
            NSLog(@"[Item completionHandler] error : %@", error);
            [weakSelf downloadStatusChanged:YCDownloadStatusFailed downloadTask:nil];
            if(!weakSelf.isRemoved) [YCDownloadDB saveItem:weakSelf];
            return ;
        }
        
        // bg completion ,maybe had no extension
        if (!self.fileExtension) [self setFileExtensionWithTask:task];
        NSError *saveError = nil;
        if([[NSFileManager defaultManager] fileExistsAtPath:self.savePath]){
            NSLog(@"[Item completionHandler] Warning file Exist at path: %@ and replaced it!", weakSelf.savePath);
            [[NSFileManager defaultManager] removeItemAtPath:self.savePath error:nil];
        }
        
        if([[NSFileManager defaultManager] moveItemAtPath:localPath toPath:self.savePath error:&saveError]){
            NSAssert(self.fileExtension, @"file extension can not nil!");
            int64_t fileSize = [YCDownloadUtils fileSizeWithPath:weakSelf.savePath];
            self->_downloadedSize = fileSize;
            self->_fileSize = fileSize;
            [weakSelf downloadStatusChanged:YCDownloadStatusFinished downloadTask:nil];
        }else{
            [weakSelf downloadStatusChanged:YCDownloadStatusFailed downloadTask:nil];
            NSLog(@"[Item completionHandler] move file failed error: %@ \nlocalPath: %@ \nsavePath:%@", saveError,localPath,self.savePath);
        }
        
    };
}

- (NSTimer *)speedTimer {
    if (!_speedTimer) {
        _speedTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(speedTimerRun) userInfo:nil repeats:true];
    }
    return _speedTimer;
}

#pragma mark - public

- (NSString *)compatibleKey {
    return [YCDownloadTask downloaderVerison];
}

- (NSString *)saveUidDirectory {
    return [[self saveRootPath] stringByAppendingPathComponent:self.uid];
}

- (NSString *)saveDirectory {
    NSString *path = [self saveUidDirectory];
    path = [path stringByAppendingPathComponent:(self.fileType ? self.fileType : @"data")];
    [YCDownloadUtils createPathIfNotExist:path];
    return path;
}

- (NSString *)saveName {
    NSString *saveName = self.fileId ? self.fileId : self.taskId;
    return [saveName stringByAppendingPathExtension: self.fileExtension.length>0 ? self.fileExtension : @"data"];
}

- (NSString *)savePath {
    return [[self saveDirectory] stringByAppendingPathComponent:[self saveName]];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<YCDownloadTask: %p>{taskId: %@, url: %@ fileId: %@}", self, self.taskId, self.downloadURL, self.fileId];
}

-(void)dealloc {
    [self invalidateSpeedTimer];
}

@end
