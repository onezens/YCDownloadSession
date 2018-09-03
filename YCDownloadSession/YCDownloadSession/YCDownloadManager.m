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

@interface YCDownloadManager ()
@property (nonatomic, assign) BOOL localPushOn;
@property (nonatomic, strong) NSCache *memCache;
@end

@implementation YCDownloadManager

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
        _memCache = [NSCache new];
        _memCache.countLimit = 100;
        _memCache.totalCostLimit = 1024 * 1024 * 0.5;
    }
    return self;
}

- (void)saveDownloadItem:(YCDownloadItem *)item {
    [YCDownloadDB saveItem:item];
}

- (NSString *)downloadItemSavePath {
    NSString *saveDir = @"";
    return [saveDir stringByAppendingFormat:@"/video/items.data"];
}

- (void)addNotification {
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveDownloadItems) name:kDownloadStatusChangedNoti object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadAllTaskFinished) name:kDownloadAllTaskFinishedNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadTaskFinishedNoti:) name:kDownloadTaskFinishedNoti object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveDownloadItems) name:kDownloadNeedSaveDataNoti object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadUserChanged) name:kDownloadUserIdentifyChanged object:nil];
}


#pragma mark - public

+ (void)setMaxTaskCount:(NSInteger)count {
    [YCDownloadMgr setMaxTaskCount: count];
}

+ (void)startDownloadWithItem:(YCDownloadItem *)item {
    [YCDownloadMgr startDownloadWithItem:item priority:NSURLSessionTaskPriorityDefault];
}

+ (void)startDownloadWithItem:(YCDownloadItem *)item priority:(float)priority {
    [YCDownloadMgr startDownloadWithItem:item priority:priority];
}

+ (void)startDownloadWithUrl:(NSString *)downloadURLString fileName:(NSString *)fileName imageUrl:(NSString *)imagUrl{
    [YCDownloadMgr startDownloadWithUrl:downloadURLString fileName:fileName imageUrl:imagUrl];
}

+ (void)startDownloadWithUrl:(NSString *)downloadURLString fileName:(NSString *)fileName imageUrl:(NSString *)imagUrl fileId:(NSString *)fileId{
    [YCDownloadMgr startDownloadWithUrl:downloadURLString fileName:fileName imageUrl:imagUrl fileId:fileId];
}

+ (void)pauseDownloadWithItem:(YCDownloadItem *)item {
    item.downloadStatus = YCDownloadStatusPaused;
    [YCDownloadMgr pauseDownloadWithItem:item];
}

+ (void)resumeDownloadWithItem:(YCDownloadItem *)item {
    item.downloadStatus = YCDownloadStatusDownloading;
    [YCDownloadMgr resumeDownloadWithItem:item];
}

+ (void)stopDownloadWithItem:(YCDownloadItem *)item {
    [YCDownloadMgr stopDownloadWithItem:item];
}

/**
 暂停所有的下载
 */
+ (void)pauseAllDownloadTask {
    [YCDownloadMgr pauseAllDownloadTask];
}

+ (void)resumeAllDownloadTask {
    [YCDownloadMgr resumeAllDownloadTask];
}

+ (void)removeAllCache {
    [YCDownloadMgr removeAllCache];
}

+ (NSArray *)downloadList {
    return [YCDownloadDB fetchAllDownloadingItem];
}
+ (NSArray *)finishList {
    return [YCDownloadDB fetchAllDownloadedItem];
}

+ (BOOL)isDownloadWithId:(NSString *)tid {
    return [self downloadItemWithId:tid] != nil;
}

+ (YCDownloadStatus)downloasStatusWithId:(NSString *)tid {
    YCDownloadItem *item = [self downloadItemWithId:tid];
    return item ? item.downloadStatus : YCDownloadStatusNotExist;
}

+ (YCDownloadItem *)downloadItemWithId:(NSString *)tid {
    YCDownloadItem *item = [YCDownloadDB itemWithFid:tid];
    if (!item) item = [YCDownloadDB itemWithUrl:tid];
    return item;
}

+(void)allowsCellularAccess:(BOOL)isAllow {
    [YCDownloadMgr allowsCellularAccess:isAllow];
}

+(void)localPushOn:(BOOL)isOn {
    [YCDownloadMgr localPushOn:isOn];
}


#pragma mark - assgin

//- (void)setGetUserIdentify:(GetUserIdentifyBlk)getUserIdentify {
//     [YCDownloadSession setUserIdentify:getUserIdentify];
//    _getUserIdentify = getUserIdentify;
//}

- (void)setMaxTaskCount:(NSInteger)count{
//    [YCDownloadSession downloadSession].maxTaskCount = count;
}

- (void)downloadUserChanged {
    
}

#pragma mark tools
+(BOOL)isAllowsCellularAccess{
    return [YCDownloadMgr isAllowsCellularAccess];
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
    [YCDownloadDB saveItem:item];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:item.downloadUrl]];
    YCDownloadTask *task = [[YCDownloader downloader] downloadWithRequest:request progress:item.progressHanlder completion:item.completionHanlder priority:priority];
    item.taskId = task.taskId;
//    YCDownloadTask *task =  [YCDownloadSession.downloadSession startDownloadWithUrl:item.downloadUrl fileId:item.fileId delegate:item priority:priority];
//    task.enableSpeed = item.enableSpeed;
}

- (void)startDownloadWithUrl:(NSString *)downloadURLString fileName:(NSString *)fileName imageUrl:(NSString *)imagUrl {
    [self startDownloadWithUrl:downloadURLString fileName:fileName imageUrl:imagUrl fileId:downloadURLString];
}

//下载文件时候的保存名称，如果没有fileid那么必须 savename = nil
- (NSString *)saveNameForItem:(YCDownloadItem *)item {
    NSString *saveName = [item.downloadUrl isEqualToString:item.fileId] ? nil : item.fileId;
    return saveName;
}

- (YCDownloadItem *)itemWithTaskId:(NSString *)taskId {
    NSArray *items = [YCDownloadDB fetchAllDownloadItem];
    __block YCDownloadItem *item = nil;
    [items enumerateObjectsUsingBlock:^(YCDownloadItem *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.taskId isEqualToString:taskId]) {
            item = obj;
            *stop = true;
        }
    }];
    return item;
}

- (void)removeItemWithTaskId:(NSString *)taskId {
    [YCDownloadDB removeItemWithTaskId:taskId];
}

- (void)startDownloadWithUrl:(NSString *)downloadURLString fileName:(NSString *)fileName imageUrl:(NSString *)imagUrl fileId:(NSString *)fileId{
    
    if (downloadURLString.length == 0 && fileId.length == 0) return;
    YCDownloadItem *item = [YCDownloadItem itemWithUrl:downloadURLString fileId:fileId];
//    item.fileName = fileName;
//    item.thumbImageUrl = imagUrl;
    item.downloadStatus = YCDownloadStatusDownloading;
    [self startDownloadWithItem:item priority:NSURLSessionTaskPriorityDefault];
}

- (YCDownloadTask *)taskWithItem:(YCDownloadItem *)item {
    YCDownloadTask *task = nil;
    //mem
    task = [_memCache objectForKey:item.taskId];
    //db
    if(!task) task = [YCDownloadDB taskWithTid:item.taskId];
    return task;
}

- (void)resumeDownloadWithItem:(YCDownloadItem *)item{
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
    YCDownloadTask *task  = [self taskWithItem:item];
    [[YCDownloader downloader] pauseDownloadTask:task];
    [self saveDownloadItem:item];
}

- (void)stopDownloadWithItem:(YCDownloadItem *)item {
    if (item == nil )  return;
    YCDownloadTask *task  = [self taskWithItem:item];
    [[YCDownloader downloader] cancelDownloadTask:task];
    [[NSFileManager defaultManager] removeItemAtPath:item.savePath error:nil];
    [self removeItemWithTaskId:item.taskId];
    [self saveDownloadItem:item];
}

- (void)pauseAllDownloadTask {
//    [[YCDownloadSession downloadSession] pauseAllDownloadTask];
}

- (void)removeAllCache {
    [self pauseAllDownloadTask];
    [YCDownloadDB removeAllItems];
}

- (void)resumeAllDownloadTask{
    NSArray <YCDownloadItem *> *downloading = [YCDownloadDB fetchAllDownloadingItem];
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
