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

@property (nonatomic, strong) NSMutableDictionary *itemsDictM;

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
        [self initDownloadData];
        [self addNotification];
    }
    return self;
}

- (void)initDownloadData {
    [self getDownloadItems];
    if(!self.itemsDictM) self.itemsDictM = [NSMutableDictionary dictionary];
}

- (void)saveDownloadItems {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSLock *saveLock = [[NSLock alloc] init];
        [saveLock lock];
        [NSKeyedArchiver archiveRootObject:self.itemsDictM toFile:[self downloadItemSavePath]];
        [saveLock unlock];
    });
}

- (void)getDownloadItems {
    NSMutableDictionary *items = [NSKeyedUnarchiver unarchiveObjectWithFile:[self downloadItemSavePath]];;
    self.itemsDictM = items;
}

- (NSString *)downloadItemSavePath {
    NSString *saveDir = [YCDownloadSession saveRootPath];
    return [saveDir stringByAppendingFormat:@"/video/items.data"];
}

- (void)addNotification {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveDownloadItems) name:kDownloadStatusChangedNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadTaskFinishedNoti:) name:kDownloadTaskFinishedNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveDownloadItems) name:kDownloadNeedSaveDataNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadUserChanged) name:kDownloadUserIdentifyChanged object:nil];
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
    [YCDownloadMgr pauseDownloadWithItem:item];
}

+ (void)resumeDownloadWithItem:(YCDownloadItem *)item {
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
    return [YCDownloadMgr downloadList];
}
+ (NSArray *)finishList {
    return [YCDownloadMgr finishList];
}

+ (BOOL)isDownloadWithId:(NSString *)downloadId {
    return [YCDownloadMgr isDownloadWithId:downloadId];
}

+ (YCDownloadStatus)downloasStatusWithId:(NSString *)downloadId {
    return [YCDownloadMgr downloasStatusWithId:downloadId];
}

+ (YCDownloadItem *)downloadItemWithId:(NSString *)downloadId {
    return [YCDownloadMgr itemWithIdentifier:downloadId];
}

+(void)allowsCellularAccess:(BOOL)isAllow {
    [YCDownloadMgr allowsCellularAccess:isAllow];
}


#pragma mark - assgin

- (void)setGetUserIdentify:(GetUserIdentifyBlk)getUserIdentify {
     [YCDownloadSession setUserIdentify:getUserIdentify];
    _getUserIdentify = getUserIdentify;
    [self initDownloadData];
}

- (void)setMaxTaskCount:(NSInteger)count{
    [YCDownloadSession downloadSession].maxTaskCount = count;
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

+ (void)saveDownloadStatus {
    [[YCDownloadManager manager] saveDownloadItems];
}

#pragma mark - private

- (void)downloadUserChanged{
    [self initDownloadData];
}

- (void)startDownloadWithItem:(YCDownloadItem *)item priority:(float)priority{
    if(!item) return;
    YCDownloadItem *oldItem = [self itemWithIdentifier:item.taskId];
    if (oldItem.downloadStatus == YCDownloadStatusFinished) return;
    [self.itemsDictM setValue:item forKey:item.taskId];
    YCDownloadTask *task =  [YCDownloadSession.downloadSession startDownloadWithUrl:item.downloadUrl fileId:item.fileId delegate:item priority:priority];
    task.enableSpeed = item.enableSpeed;
}

- (void)startDownloadWithUrl:(NSString *)downloadURLString fileName:(NSString *)fileName imageUrl:(NSString *)imagUrl {
    [self startDownloadWithUrl:downloadURLString fileName:fileName imageUrl:imagUrl fileId:downloadURLString];
}

//下载文件时候的保存名称，如果没有fileid那么必须 savename = nil
- (NSString *)saveNameForItem:(YCDownloadItem *)item {
    
    NSString *saveName = [item.downloadUrl isEqualToString:item.fileId] ? nil : item.fileId;
    return saveName;
}

- (void)startDownloadWithUrl:(NSString *)downloadURLString fileName:(NSString *)fileName imageUrl:(NSString *)imagUrl fileId:(NSString *)fileId{
    
    if (downloadURLString.length == 0 && fileId.length == 0) return;
    NSString *taskId = [YCDownloadTask taskIdForUrl:downloadURLString fileId:fileId];
    YCDownloadItem *item = [self.itemsDictM valueForKey:taskId];
    if (item == nil) {
        item = [[YCDownloadItem alloc] initWithUrl:downloadURLString fileId:fileId];
    }
    item.fileName = fileName;
    item.thumbImageUrl = imagUrl;
    [self startDownloadWithItem:item priority:NSURLSessionTaskPriorityDefault];
}

- (void)resumeDownloadWithItem:(YCDownloadItem *)item{
    YCDownloadTask *task = [YCDownloadSession.downloadSession taskForTaskId:item.taskId];
    task.delegate = item;
    [YCDownloadSession.downloadSession resumeDownloadWithTaskId:item.taskId];
    [self saveDownloadItems];
}


- (void)pauseDownloadWithItem:(YCDownloadItem *)item {
    [YCDownloadSession.downloadSession pauseDownloadWithTaskId:item.taskId];
    [self saveDownloadItems];
}

- (void)stopDownloadWithItem:(YCDownloadItem *)item {
    if (item == nil )  return;
    [YCDownloadSession.downloadSession stopDownloadWithTaskId: item.taskId];
    [self.itemsDictM removeObjectForKey:item.taskId];
    [self saveDownloadItems];
}

- (void)pauseAllDownloadTask {
    [[YCDownloadSession downloadSession] pauseAllDownloadTask];
}

- (void)removeAllCache {
    [self.itemsDictM.copy enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, YCDownloadItem *  _Nonnull obj, BOOL * _Nonnull stop) {
        [self stopDownloadWithItem:obj];
    }];
}

- (void)resumeAllDownloadTask{
    [self.itemsDictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        YCDownloadItem *item = obj;
        if (item.downloadStatus == YCDownloadStatusPaused || item.downloadStatus == YCDownloadStatusFailed) {
            [self resumeDownloadWithItem:item];
        }
    }];
}

-(NSArray *)downloadList {
    NSMutableArray *arrM = [NSMutableArray array];
    
    [self.itemsDictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        YCDownloadItem *item = obj;
        if(item.downloadStatus != YCDownloadStatusFinished){
            [arrM addObject:item];
        }
    }];
    
    return arrM;
}
- (NSArray *)finishList {
    NSMutableArray *arrM = [NSMutableArray array];
    [self.itemsDictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        YCDownloadItem *item = obj;
        if(item.downloadStatus == YCDownloadStatusFinished){
            [arrM addObject:item];
        }
    }];
    return arrM;
}

/**id 可以是downloadUrl，也可以是fileId，首先从fileId开始找，然后downloadUrl*/

- (YCDownloadItem *)itemWithIdentifier:(NSString *)identifier {
    __block YCDownloadItem *item = [self.itemsDictM valueForKey:identifier];
    if (item) return item;
    [self.itemsDictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        YCDownloadItem *dItem = obj;
        if([dItem.fileId isEqualToString:identifier]){
            item = dItem;
            *stop = true;
        }
    }];
    
    if(item) return item;
    
    [self.itemsDictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        YCDownloadItem *dItem = obj;
        if([dItem.downloadUrl isEqualToString:identifier]){
            item = dItem;
            *stop = true;
        }
    }];
    
    return item;
}

-(void)allowsCellularAccess:(BOOL)isAllow {
    [[YCDownloadSession downloadSession] allowsCellularAccess:isAllow];
}

- (BOOL)isAllowsCellularAccess {
    return [[YCDownloadSession downloadSession] isAllowsCellularAccess];
}

- (BOOL)isDownloadWithId:(NSString *)downloadId {
    
    YCDownloadItem *item = [self itemWithIdentifier:downloadId];
    return item != nil;
}

- (YCDownloadStatus)downloasStatusWithId:(NSString *)downloadId {
    YCDownloadItem *item = [self itemWithIdentifier:downloadId];
    if (!item) {
        return -1;
    }
    return item.downloadStatus;
}


#pragma mark - notificaton


- (void)downloadTaskFinishedNoti:(NSNotification *)noti{
    [self saveDownloadItems];
}


-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
