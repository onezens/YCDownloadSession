//
//  YCDownloadManager.m
//  YCDownloadSession
//
//  Created by wz on 17/3/24.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Contact me: http://www.onezen.cc
//  Github:     https://github.com/onezens/YCDownloadSession
//

#import "YCDownloadManager.h"
#import "YCDownloadUtils.h"
#import "YCDownloader.h"

@interface YCDownloadItem(Mgr)
@property (nonatomic, assign) BOOL isRemoved;
@end

@interface YCDownloadManager ()

@property (nonatomic, assign) BOOL localPushOn;
@property (nonatomic, strong) NSMutableDictionary <NSString *, YCDownloadItem *> *memCache;
@end

@implementation YCDownloadManager

@synthesize uid = _uniqueId;
static id _instance;

#pragma mark - init

+ (instancetype)manager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self addNotification];
        _memCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)saveDownloadItem:(YCDownloadItem *)item {
    [YCDownloadDB saveItem:item];
}

- (void)addNotification {
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveDownloadItems) name:kDownloadStatusChangedNoti object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadAllTaskFinished) name:kDownloadAllTaskFinishedNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadTaskFinishedNoti:) name:kDownloadTaskFinishedNoti object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveDownloadItems) name:kDownloadNeedSaveDataNoti object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadUserChanged) name:kDownloadUserIdentifyChanged object:nil];
}


#pragma mark - public


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
    return [YCDownloadManager itemsWithDownloadUrl:downloadUrl];
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
    [self.memCache removeAllObjects];
    _uniqueId = uid;
}

- (NSString *)uid {
    return _uniqueId ? : @"YCDownloadUID";
}

#pragma mark tools

+(void)localPushOn:(BOOL)isOn {
    [YCDownloadMgr localPushOn:isOn];
}

+ (NSUInteger)videoCacheSize {
    NSUInteger size = 0;
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

#pragma mark - private

- (void)startDownloadWithItem:(YCDownloadItem *)item priority:(float)priority{
    if(!item) return;
    YCDownloadItem *oldItem = [YCDownloadDB itemWithTaskId:item.taskId];
    if (oldItem.downloadStatus == YCDownloadStatusFinished) return;
    item.downloadStatus = YCDownloadStatusWaiting;
    item.uid = self.uid;
    item.saveRootPath = self.saveRootPath;
    item.fileType = item.fileType ? : @"video";
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:item.downloadURL]];
    YCDownloadTask *task = [[YCDownloader downloader] downloadWithRequest:request progress:item.progressHanlder completion:item.completionHanlder priority:priority];
    item.taskId = task.taskId;
    [YCDownloadDB saveItem:item];
}
- (void)startDownloadWithUrl:(NSString *)downloadURLString fileId:(NSString *)fileId  priority:(float)priority extraData:(NSData *)extraData {
    YCDownloadItem *item = [YCDownloadItem itemWithUrl:downloadURLString fileId:fileId];
    item.extraData = extraData;
    [self startDownloadWithItem:item priority:priority];
}

- (YCDownloadItem *)itemWithTaskId:(NSString *)taskId {
    return [YCDownloadDB itemWithTaskId:taskId];
}

- (void)removeItemWithTaskId:(NSString *)taskId {
    [YCDownloadDB removeItemWithTaskId:taskId];
}

- (YCDownloadTask *)taskWithItem:(YCDownloadItem *)item {
    YCDownloadTask *task = nil;
//    task = [_memCache objectForKey:item.taskId];
    if(!task) task = [YCDownloadDB taskWithTid:item.taskId];
    return task;
}

- (void)resumeDownloadWithItem:(YCDownloadItem *)item{
    item.downloadStatus = YCDownloadStatusDownloading;
    if ([[YCDownloader downloader] canResumeTaskWithTid:item.taskId]) {
        YCDownloadTask *task = [self taskWithItem:item];
        task.completionHanlder = item.completionHanlder;
        task.progressHandler = item.progressHanlder;
        [[YCDownloader downloader] resumeDownloadTask:task];
    }else{
        [self startDownloadWithItem:item priority:0];
    }
    [self accessibilityNavigationStyle];
}

- (void)pauseDownloadWithItem:(YCDownloadItem *)item {
    item.downloadStatus = YCDownloadStatusPaused;
    YCDownloadTask *task  = [self taskWithItem:item];
    [[YCDownloader downloader] pauseDownloadTask:task];
    [self saveDownloadItem:item];
}

- (void)stopDownloadWithItem:(YCDownloadItem *)item {
    if (item == nil )  return;
    item.isRemoved = true;
    YCDownloadTask *task  = [self taskWithItem:item];
    [[YCDownloader downloader] cancelDownloadTask:task];
    [[NSFileManager defaultManager] removeItemAtPath:item.savePath error:nil];
    [self removeItemWithTaskId:item.taskId];
    [YCDownloadDB removeTask:task];
}


- (void)pauseAllDownloadTask {
    [[YCDownloadDB fetchAllDownloadingItemWithUid:self.uid] enumerateObjectsUsingBlock:^(YCDownloadItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self pauseDownloadWithItem:obj];
    }];
}

- (void)removeAllCache {
    [[YCDownloadDB fetchAllDownloadItemWithUid:self.uid] enumerateObjectsUsingBlock:^(YCDownloadItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        YCDownloadTask *task = [self taskWithItem:obj];
        [self stopDownloadWithItem:obj];
        [YCDownloadDB removeTask:task];
    }];
    [YCDownloadDB removeAllItemsWithUid:self.uid];
}

- (void)resumeAllDownloadTask{
    NSArray <YCDownloadItem *> *downloading = [YCDownloadDB fetchAllDownloadingItemWithUid:self.uid];
    [downloading enumerateObjectsUsingBlock:^(YCDownloadItem *item, NSUInteger idx, BOOL * _Nonnull stop) {
        if (item.downloadStatus == YCDownloadStatusPaused || item.downloadStatus == YCDownloadStatusFailed) {
            [self resumeDownloadWithItem:item];
        }
    }];
}

-(void)allowsCellularAccess:(BOOL)isAllow {
    [YCDownloader downloader].allowsCellularAccess = isAllow;
}

- (BOOL)isAllowsCellularAccess {
    return [YCDownloader downloader].allowsCellularAccess;
}

- (void)localPushOn:(BOOL)isOn {
    self.localPushOn = isOn;
}

- (YCDownloadItem *)itemWithFileId:(NSString *)fid {
    return [YCDownloadDB itemWithFid:fid uid:self.uid];
}

- (NSArray *)itemsWithDownloadUrl:(NSString *)downloadUrl {
    return [YCDownloadDB itemsWithUrl:downloadUrl uid:self.uid];
}

#pragma mark notificaton

- (void)downloadAllTaskFinished{
    [self localPushWithTitle:@"YCDownloadSession" detail:@"所有的下载任务已完成！"];
}

- (void)downloadTaskFinishedNoti:(NSNotification *)noti{
    
    YCDownloadItem *item = noti.object;
    if (item) {
        NSString *detail = @"";// [NSString stringWithFormat:@"%@ 视频，已经下载完成！", item.fileName];
        [self localPushWithTitle:@"YCDownloadSession" detail:detail];
    }
    [self saveDownloadItem:item];
}

#pragma mark local push

- (void)localPushWithTitle:(NSString *)title detail:(NSString *)body  {
    
    if (!self.localPushOn || title.length == 0) return;
    UILocalNotification *localNote = [[UILocalNotification alloc] init];
    localNote.fireDate = [NSDate dateWithTimeIntervalSinceNow:3.0];
    localNote.alertBody = body;
    localNote.alertAction = @"滑动来解锁";
    localNote.hasAction = NO;
    localNote.soundName = @"default";
    localNote.userInfo = @{@"type" : @1};
    [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
