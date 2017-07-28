//
//  YCDownloadManager.m
//  YCDownloadSession
//
//  Created by wangzhen on 17/3/24.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "YCDownloadManager.h"
#import "YCDownloadSession.h"


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
        [self getDownloadItems];
        if(!self.itemsDictM) self.itemsDictM = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)saveDownloadItems {
    [NSKeyedArchiver archiveRootObject:self.itemsDictM toFile:[self downloadItemSavePath]];
}

- (void)getDownloadItems {
    self.itemsDictM = [NSKeyedUnarchiver unarchiveObjectWithFile:[self downloadItemSavePath]];
}

- (NSString *)downloadItemSavePath {
    NSString *saveDir = [YCDownloadTask saveDir];
    return [saveDir stringByAppendingPathComponent:@"items.data"];
}


#pragma mark - public



/**
 开始一个后台下载任务
 
 @param downloadURLString 下载url

 */
+ (void)startDownloadWithUrl:(NSString *)downloadURLString fileName:(NSString *)fileName thumbImageUrl:(NSString *)imagUrl{
    [[YCDownloadManager manager] startDownloadWithUrl:downloadURLString fileName:fileName thumbImageUrl:imagUrl];
}

/**
 暂停一个后台下载任务
 
 @param downloadURLString 下载url
 */
+ (void)pauseDownloadWithUrl:(NSString *)downloadURLString {
    [[YCDownloadManager manager] pauseDownloadWithUrl:downloadURLString];
}

/**
 继续开始一个后台下载任务
 
 @param downloadURLString 下载url
 */
+ (void)resumeDownloadWithUrl:(NSString *)downloadURLString {
    [[YCDownloadManager manager] resumeDownloadWithUrl:downloadURLString];
}

/**
 删除一个后台下载任务，同时会删除当前任务下载的缓存数据
 
 @param downloadURLString 下载url
 */
+ (void)stopDownloadWithUrl:(NSString *)downloadURLString {
    [[YCDownloadManager manager] stopDownloadWithUrl:downloadURLString];
}



/**
 暂停所有的下载
 */
+ (void)pauseAllDownloadTask {
    [[YCDownloadManager manager] pauseAllDownloadTask];
}


+ (NSArray *)downloadList {
    return [[YCDownloadManager manager] downloadList];
}
+ (NSArray *)finishList {
    return [[YCDownloadManager manager] finishList];
}

+ (NSUInteger)videoCacheSize {
    NSUInteger size = 0;
    NSArray *downloadList = [self downloadList];
    NSArray *finishList = [self finishList];
    for (YCDownloadTask *item in downloadList) {
        size += item.downloadedSize;
    }
    for (YCDownloadTask *item in finishList) {
        size += item.fileSize;
    }
    return size;
    
}
+ (NSUInteger)fileSystemFreeSize {
    uint64_t totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalFreeSpace = [freeFileSystemSizeInBytes floatValue];
    }
    return totalFreeSpace;
}


#pragma mark - private


- (void)startDownloadWithUrl:(NSString *)downloadURLString fileName:(NSString *)fileName thumbImageUrl:(NSString *)imagUrl {
    
    YCDownloadItem *item = [[YCDownloadItem alloc] init];
    item.downloadUrl = downloadURLString;
    item.downloadStatus = YCDownloadStatusDownloading;
    item.fileName = fileName;
    item.thumbImageUrl = imagUrl;
    [self.itemsDictM setValue:item forKey:downloadURLString];
    [[YCDownloadSession downloadSession] startDownloadWithUrl:downloadURLString delegate:item];
    
}


- (void)resumeDownloadWithUrl:(NSString *)downloadURLString {
    YCDownloadItem *item = [self.itemsDictM valueForKey:downloadURLString];
    item.downloadStatus = YCDownloadStatusDownloading;
    [[YCDownloadSession downloadSession] resumeDownloadWithUrl:downloadURLString delegate:item];
}


- (void)pauseDownloadWithUrl:(NSString *)downloadURLString {
    YCDownloadItem *item = [self.itemsDictM valueForKey:downloadURLString];
    item.downloadStatus = YCDownloadStatusPaused;
    [[YCDownloadSession downloadSession] pauseDownloadWithUrl:downloadURLString];
}

- (void)stopDownloadWithUrl:(NSString *)downloadURLString {
    [self.itemsDictM removeObjectForKey:downloadURLString];
    [[YCDownloadSession downloadSession] stopDownloadWithUrl:downloadURLString];
}

- (void)pauseAllDownloadTask {
    [self.itemsDictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        YCDownloadItem *item = obj;
        item.downloadStatus = YCDownloadStatusPaused;
    }];
    [[YCDownloadSession downloadSession] pauseAllDownloadTask];
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





@end
