//
//  YCDownloadManager.m
//  YCDownloadSession
//
//  Created by wz on 17/3/24.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Contact me: http://www.onezen.cc/about/
//  Github:     https://github.com/onezens/YCDownloadSession
//

#import "YCDownloadManager.h"
#import "YCDownloadUtils.h"
#import "YCDownloader.h"
#import "YCDownloadDB.h"

#define YCDownloadMgr [YCDownloadManager manager]

@interface YCDownloader(Mgr)
- (void)endBGCompletedHandler;
@end


@interface YCDownloadItem(Mgr)
@property (nonatomic, assign) BOOL isRemoved;
@property (nonatomic, assign) BOOL noNeedStartNext;
@end

@interface YCDownloadManager ()
{
    NSString *_uniqueId;
}
@property (nonatomic, strong) NSMutableArray <YCDownloadItem *> *waitItems;
@property (nonatomic, strong) NSMutableArray <YCDownloadItem *> *runItems;
@property (nonatomic, strong) YCDConfig *config;
@end

@implementation YCDownloadManager

static id _instance;

#pragma mark - init

+ (void)mgrWithConfig:(YCDConfig *)config {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        YCDownloadMgr.config = config;
        [YCDownloadMgr initManager];
    });
}

+ (instancetype)manager {
    NSAssert(_instance, @"please set config: [YCDownloadManager mgrWithConfig:config];");
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self addNotification];
        _runItems  = [NSMutableArray array];
        _waitItems = [NSMutableArray array];
    }
    return self;
}

- (void)initManager{
    [self setUid:self.config.uid];
    [YCDownloader downloader].taskCachekMode = self.config.taskCachekMode;
    [self restoreItems];
}

- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadTaskFinishNoti:) name:kDownloadTaskFinishedNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
}

- (void)restoreItems {
    [[YCDownloadDB fetchAllDownloadItemWithUid:self.uid] enumerateObjectsUsingBlock:^(YCDownloadItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self downloadFinishedWithItem:obj];
        YCDownloadTask *task = [self taskWithItem:obj];
        if (obj.downloadStatus == YCDownloadStatusDownloading || ( task.isRunning && self.config.launchAutoResumeDownload)) {
            obj.downloadStatus = YCDownloadStatusDownloading;
            task.completionHandler = obj.completionHandler;
            task.progressHandler = obj.progressHandler;
            if (task.state != NSURLSessionTaskStateRunning) {
                obj.downloadStatus = YCDownloadStatusPaused;
            }
            [self.runItems addObject:obj];
        }
        if(self.config.launchAutoResumeDownload){
            if(obj.downloadStatus == YCDownloadStatusWaiting){
                [self.waitItems addObject:obj];
            }
        }else{
            if (obj.downloadStatus == YCDownloadStatusWaiting || obj.downloadStatus==YCDownloadStatusDownloading) {
                [self pauseDownloadWithItem:obj];
            }
        }
    }];
    if (self.config.launchAutoResumeDownload && self.waitItems.count>0) {
        [self resumeDownloadWithItem:self.waitItems.firstObject];
    }
    [YCDownloadDB saveAllData];
}

#pragma mark - public

+ (void)updateUid:(NSString *)uid {
    [YCDownloadMgr setUid:uid];
}

+ (void)startDownloadWithUrl:(NSString *)downloadURLString{
    [self startDownloadWithUrl:downloadURLString fileId:nil priority:NSURLSessionTaskPriorityDefault extraData:nil];
}

+ (void)startDownloadWithUrl:(NSString *)downloadURLString fileId:(NSString *)fileId  priority:(float)priority extraData:(NSData *)extraData {
    [YCDownloadMgr startDownloadWithUrl:downloadURLString fileId:fileId priority:priority extraData:extraData];
}

+ (void)startDownloadWithItem:(YCDownloadItem *)item {
    [YCDownloadMgr startDownloadWithItem:item priority:NSURLSessionTaskPriorityDefault];
}

+ (void)startDownloadWithItem:(YCDownloadItem *)item priority:(float)priority {
    [YCDownloadMgr startDownloadWithItem:item priority:priority];
}


+ (void)pauseDownloadWithItem:(YCDownloadItem *)item {
    [YCDownloadMgr pauseDownloadWithItem:item];
}

+ (void)resumeDownloadWithItem:(YCDownloadItem *)item {
    [YCDownloadMgr resumeDownloadWithItem:item];
}

+ (void)stopDownloadWithItem:(YCDownloadItem *)item {
    [YCDownloadMgr stopDownloadWithItem:item];
}

+ (void)pauseAllDownloadTask {
    [YCDownloadMgr pauseAllDownloadTask];
}

+ (void)resumeAllDownloadTask {
    [YCDownloadMgr resumeAllDownloadTask];
}

+ (void)removeAllCache {
    [YCDownloadMgr removeAllCache];
}

+ (YCDownloadItem *)itemWithFileId:(NSString *)fid {
    return [YCDownloadMgr itemWithFileId:fid];
}

+ (NSArray *)itemsWithDownloadUrl:(NSString *)downloadUrl {
    return [YCDownloadMgr itemsWithDownloadUrl:downloadUrl];
}

+ (NSArray *)downloadList {
    return [YCDownloadDB fetchAllDownloadingItemWithUid:YCDownloadMgr.uid];
}
+ (NSArray *)finishList {
    return [YCDownloadDB fetchAllDownloadedItemWithUid:YCDownloadMgr.uid];
}

#pragma mark - setter or getter

+(BOOL)isAllowsCellularAccess{
    return [YCDownloadMgr isAllowsCellularAccess];
}
+(void)allowsCellularAccess:(BOOL)isAllow {
    [YCDownloadMgr allowsCellularAccess:isAllow];
}

- (void)setUid:(NSString *)uid {
    if ([_uniqueId isEqualToString:uid]) return;
    [self pauseAllDownloadTask];
    _uniqueId = uid;
}

- (NSString *)uid {
    return _uniqueId ? : @"YCDownloadUID";
}

#pragma mark - Handler

- (void)appWillTerminate {
    [self pauseAllDownloadTask];
}

- (void)saveDownloadItem:(YCDownloadItem *)item {
    [YCDownloadDB saveItem:item];
}

- (void)downloadTaskFinishNoti:(NSNotification *)noti {
    YCDownloadItem *item = noti.object;
    [self.runItems removeObject:item];
    [self startNextDownload];
    if (self.runItems.count==0 && self.waitItems.count==0) {
        NSLog(@"[startNextDownload] all download task finished");
        [[YCDownloader downloader] endBGCompletedHandler];
    }
}
- (void)startNextDownload {
    YCDownloadItem *item = self.waitItems.firstObject;
    if (!item) return;
    [self.waitItems removeObject:item];
    [self resumeDownloadWithItem:item];
}

+ (int64_t)videoCacheSize {
    int64_t size = 0;
    NSArray *downloadList = [self downloadList];
    NSArray *finishList = [self finishList];
    for (YCDownloadTask *task in downloadList) {
        size += task.downloadedSize;
    }
    for (YCDownloadTask *task in finishList) {
        size += task.fileSize;
    }
    return size;
}

- (BOOL)canResumeDownload {
    return self.runItems.count<self.config.maxTaskCount;
}

#pragma mark - private

- (void)startDownloadWithItem:(YCDownloadItem *)item priority:(float)priority{
    if(!item) return;
    YCDownloadItem *oldItem = [YCDownloadDB itemWithTaskId:item.taskId];
    if (oldItem && [self downloadFinishedWithItem:oldItem]) {
        NSLog(@"[startDownloadWithItem] detect item finished!");
        [self startNextDownload];
        return;
    }
    item.downloadStatus = YCDownloadStatusWaiting;
    item.uid = self.uid;
    item.saveRootPath = self.config.saveRootPath;
    item.fileType = item.fileType ? : @"video";
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:item.downloadURL]];
    YCDownloadTask *task = [[YCDownloader downloader] downloadWithRequest:request progress:item.progressHandler completion:item.completionHandler priority:priority];
    item.taskId = task.taskId;
    [YCDownloadDB saveItem:item];
    [self resumeDownloadWithItem:item];
}

- (void)startDownloadWithUrl:(NSString *)downloadURLString fileId:(NSString *)fileId  priority:(float)priority extraData:(NSData *)extraData {
    YCDownloadItem *item = [YCDownloadItem itemWithUrl:downloadURLString fileId:fileId];
    item.extraData = extraData;
    [self startDownloadWithItem:item priority:priority];
}

- (BOOL)downloadFinishedWithItem:(YCDownloadItem *)item {
    int64_t localFileSize = [YCDownloadUtils fileSizeWithPath:item.savePath];
    BOOL fileFinished = localFileSize>0 && localFileSize == item.fileSize;
    if (fileFinished) {
        [item setValue:@(localFileSize) forKey:@"_downloadedSize"];
        item.downloadStatus = YCDownloadStatusFinished;
        return true;
    }
    if (item.downloadStatus == YCDownloadStatusFinished){
        NSLog(@"[downloadFinishedWithItem] status finished to failed, reason: savePath error! %@", item.savePath);
        item.downloadStatus = YCDownloadStatusFailed;
    }
    if ([[NSFileManager defaultManager] fileExistsAtPath:item.savePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:item.savePath error:nil];
    }
    return false;
}

- (YCDownloadItem *)itemWithTaskId:(NSString *)taskId {
    return [YCDownloadDB itemWithTaskId:taskId];
}

- (void)removeItemWithTaskId:(NSString *)taskId {
    [YCDownloadDB removeItemWithTaskId:taskId];
}

- (YCDownloadTask *)taskWithItem:(YCDownloadItem *)item {
    NSAssert(item.taskId, @"item taskid not nil");
    YCDownloadTask *task = nil;
    task = [YCDownloadDB taskWithTid:item.taskId];
    return task;
}

- (void)resumeDownloadWithItem:(YCDownloadItem *)item{
    if ([self downloadFinishedWithItem:item]) {
        NSLog(@"[resumeDownloadWithItem] detect item finished : %@", item);
        [self startNextDownload];
        return;
    }
    if (![self canResumeDownload]) {
        item.downloadStatus = YCDownloadStatusWaiting;
        [self.waitItems addObject:item];
        return;
    }
    item.downloadStatus = YCDownloadStatusDownloading;
    YCDownloadTask *task = [self taskWithItem:item];
    task.completionHandler = item.completionHandler;
    task.progressHandler = item.progressHandler;
    if([[YCDownloader downloader] resumeTask:task]) {
        [self.runItems addObject:item];
        return;
    }
    //[self startDownloadWithItem:item priority:task.priority];
}


- (void)pauseDownloadWithItem:(YCDownloadItem *)item {
    item.downloadStatus = YCDownloadStatusPaused;
    YCDownloadTask *task = [self taskWithItem:item];
    [[YCDownloader downloader] pauseTask:task];
    [self saveDownloadItem:item];
    [self.runItems removeObject:item];
    [self.waitItems removeObject:item];
    if(!item.noNeedStartNext) [self startNextDownload];
}

- (void)stopDownloadWithItem:(YCDownloadItem *)item {
    if (item == nil)  return;
    item.isRemoved = true;
    YCDownloadTask *task  = [self taskWithItem:item];
    [[YCDownloader downloader] cancelTask:task];
    BOOL isExist = [[NSFileManager defaultManager] fileExistsAtPath:item.savePath];
    NSLog(@"[remove item] isExist : %d path: %@", isExist, item.savePath);
    [[NSFileManager defaultManager] removeItemAtPath:item.savePath error:nil];
    [self removeItemWithTaskId:item.taskId];
    [YCDownloadDB removeTask:task];
    [self.runItems removeObject:item];
    [self.waitItems removeObject:item];
    if(!item.noNeedStartNext) [self startNextDownload];
}

- (void)pauseAllDownloadTask {
    [[YCDownloadDB fetchAllDownloadingItemWithUid:self.uid] enumerateObjectsUsingBlock:^(YCDownloadItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.downloadStatus == YCDownloadStatusWaiting || obj.downloadStatus == YCDownloadStatusDownloading) {
            obj.noNeedStartNext = true;
            [self pauseDownloadWithItem:obj];
        }
    }];
}

- (void)removeAllCache {
    [[YCDownloadDB fetchAllDownloadItemWithUid:self.uid] enumerateObjectsUsingBlock:^(YCDownloadItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.noNeedStartNext = true;
        [self stopDownloadWithItem:obj];
    }];
}

- (void)resumeAllDownloadTask{
    NSArray <YCDownloadItem *> *downloading = [YCDownloadDB fetchAllDownloadingItemWithUid:self.uid];
    [downloading enumerateObjectsUsingBlock:^(YCDownloadItem *item, NSUInteger idx, BOOL * _Nonnull stop) {
        if (item.downloadStatus == YCDownloadStatusPaused || item.downloadStatus == YCDownloadStatusFailed) {
            [self resumeDownloadWithItem:item];
        }
    }];
    [YCDownloadDB saveAllData];
}

-(void)allowsCellularAccess:(BOOL)isAllow {
    [YCDownloader downloader].allowsCellularAccess = isAllow;
}

- (BOOL)isAllowsCellularAccess {
    return [YCDownloader downloader].allowsCellularAccess;
}

- (YCDownloadItem *)itemWithFileId:(NSString *)fid {
    return [YCDownloadDB itemWithFid:fid uid:self.uid];
}

- (NSArray *)itemsWithDownloadUrl:(NSString *)downloadUrl {
    return [YCDownloadDB itemsWithUrl:downloadUrl uid:self.uid];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end


@implementation YCDConfig

- (NSUInteger)maxTaskCount {
    return _maxTaskCount ? _maxTaskCount : 1;
}

@end
