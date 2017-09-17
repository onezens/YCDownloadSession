//
//  YCDownloadSession.m
//  YCDownloadSession
//
//  Created by wangzhen on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "YCDownloadSession.h"

#import "NSURLSession+CorrectedResumeData.h"

#define IS_IOS10ORLATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10)

@interface YCDownloadSession ()<NSURLSessionDownloadDelegate>

@property (nonatomic, strong) NSMutableDictionary *downloadItems;//正在下载的item
@property (nonatomic, strong) NSMutableDictionary *downloadedItems;//下载完成的item

@end

@implementation YCDownloadSession

static YCDownloadSession *_instance;

+ (instancetype)downloadSession {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}


- (instancetype)init {
    if (self = [super init]) {
        _downloadSession = [self getDownloadURLSession];
        NSMutableDictionary *dictM = [self.downloadSession valueForKey:@"tasks"];
        self.downloadItems = [NSKeyedUnarchiver unarchiveObjectWithFile:[self getArchiverPathIsDownloaded:false]];
        self.downloadedItems = [NSKeyedUnarchiver unarchiveObjectWithFile:[self getArchiverPathIsDownloaded:true]];
        
        //获取保存在本地的数据
        if(!self.downloadedItems) self.downloadedItems = [NSMutableDictionary dictionary];
        if(!self.downloadItems) self.downloadItems = [NSMutableDictionary dictionary];
        
        //获取背景session正在运行的task
        [dictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            YCDownloadTask *item = [self getDownloadItemWithUrl:[YCDownloadTask getURLFromTask:obj] isDownloadList:true];
            if(!item){
                [obj cancel];
            }else{
                item.downloadTask = obj;
            }
            
        }];
        //获取后台下载缓存在本地的数据
        [self.downloadedItems enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, YCDownloadTask *obj, BOOL * _Nonnull stop) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:obj.tempPath]) {
                [[NSFileManager defaultManager] moveItemAtPath:obj.tempPath toPath:[YCDownloadTask savePathWithSaveName:obj.saveName] error:nil];
                
                NSLog(@"------>>>>>>> file move to ---->>>>>");
            }
        }];
        
        BOOL wifiOnly = [[NSUserDefaults standardUserDefaults] boolForKey:@"WifiOnly"];
        [self changeStatusIsAllowCellar:wifiOnly];
        
        NSLog(@"%@", dictM);
    }
    return self;
}

- (NSURLSession *)getDownloadURLSession {
    
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
        NSString *identifier = [NSString stringWithFormat:@"%@.BackgroundSession", bundleId];
        NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        sessionConfig.allowsCellularAccess = true;
        session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                delegate:self
                                           delegateQueue:[NSOperationQueue mainQueue]];
    });
    
    return session;
}


- (void)changeStatusIsAllowCellar:(BOOL)isAllow {
    
    [self pauseAllDownloadTask];
    self.downloadSession.configuration.allowsCellularAccess = isAllow;
    [self.downloadItems enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        YCDownloadTask *item = obj;
        item.downloadTask = nil;
    }];
}

#pragma mark - event



- (void)startDownloadWithUrl:(NSString *)downloadURLString delegate:(id<YCDownloadSessionDelegate>)delegate{
    if (downloadURLString.length == 0)  return;
    
    YCDownloadTask *item = [self getDownloadItemWithUrl:downloadURLString isDownloadList:false];
    if (item) {
        
        if ([delegate respondsToSelector:@selector(downloadFinished:)]) {
            [delegate downloadFinished:item];
        }
        return;
    }
    
    item = [self getDownloadItemWithUrl:downloadURLString isDownloadList:true];
    
    if (!item) {
//        [self pauseAllDownloadTask];
        [self createDownloadTaskWithUrl:downloadURLString delegate:delegate];
    }else{
        if (item.delegate == nil ) item.delegate = delegate;
        if ([self detectDownloadItemIsFinished:item]) {
            if ([item.delegate respondsToSelector:@selector(downloadFinished:)]) {
                [item.delegate downloadFinished:item];
            }
            [self saveDownloadStatus];
            return;
        }
        
        if (item.downloadTask && item.downloadTask.state == NSURLSessionTaskStateRunning && item.resumeData.length == 0) {
            [item.downloadTask resume];
            return;
        }
        if(item.downloadedSize == 0) {
            [item.downloadTask cancel];
            item.downloadTask = nil;
        }
        [self resumeDownloadTask:item];
    }
    
}

- (void)createDownloadTaskWithUrl:(NSString *)downloadURLString delegate:(id<YCDownloadSessionDelegate>)delegate{
    NSURL *downloadURL = [NSURL URLWithString:downloadURLString];
    NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
    NSURLSessionDownloadTask *downloadTask = [self.downloadSession downloadTaskWithRequest:request];
    YCDownloadTask *item = [[YCDownloadTask alloc] init];
    item.downloadURL = downloadURLString;
    item.downloadTask = downloadTask;
    item.delegate = delegate;;
    [self.downloadItems setObject:item forKey:item.downloadURL];
    [downloadTask resume];
    [self saveDownloadStatus];
}

- (void)pauseDownloadTask:(YCDownloadTask *)item {
    [item.downloadTask cancelByProducingResumeData:^(NSData * resumeData) {
        if(resumeData.length>0) item.resumeData = resumeData;
        [self saveDownloadStatus];
        NSLog(@"pause ----->   %@     --->%zd", item.downloadURL, resumeData.length);
    }];
}

- (void)pauseDownloadWithUrl:(NSString *)downloadURLString {
    [self pauseDownloadTask:[self getDownloadItemWithUrl:downloadURLString isDownloadList:true]];
    
}
- (void)resumeDownloadWithUrl:(NSString *)downloadURLString delegate:(id<YCDownloadSessionDelegate>)delegate{
    YCDownloadTask *item = [self getDownloadItemWithUrl:downloadURLString isDownloadList:true];
    if(delegate) item.delegate = delegate;
    [self resumeDownloadTask: item];
}


- (void)pauseAllDownloadTask{
    [self.downloadItems enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [self pauseDownloadTask:obj];
    }];
}

- (void)stopDownloadWithItem:(YCDownloadTask *)item {
    
    [item.downloadTask cancel];
}

- (void)stopDownloadWithUrl:(NSString *)downloadURLString {
    @try {
        [self stopDownloadWithItem:[self getDownloadItemWithUrl:downloadURLString isDownloadList:true]];
        [self.downloadItems removeObjectForKey:downloadURLString];
        [self.downloadedItems removeObjectForKey:downloadURLString];
    } @catch (NSException *exception) {  }
    [self saveDownloadStatus];
}

- (void)resumeDownloadTask:(YCDownloadTask *)item {
    
    if(!item) return;
    if ([self detectDownloadItemIsFinished:item]) {
        if ([item.delegate respondsToSelector:@selector(downloadFinished:)]) {
            [item.delegate downloadFinished:item];
        }
        [self saveDownloadStatus];
        return;
    }
    
    NSData *data = item.resumeData;
    if (data.length > 0) {
        if(item.downloadTask && item.downloadTask.state == NSURLSessionTaskStateRunning){
            return;
        }
        NSURLSessionDownloadTask *downloadTask = nil;
        if (IS_IOS10ORLATER) {
            @try { //非ios10 升级到ios10会引起崩溃
                downloadTask = [self.downloadSession downloadTaskWithCorrectResumeData:data];
            } @catch (NSException *exception) {
                downloadTask = [self.downloadSession downloadTaskWithResumeData:data];
            }
        } else {
            downloadTask = [self.downloadSession downloadTaskWithResumeData:data];
        }
        item.downloadTask = downloadTask;
        [downloadTask resume];
        item.resumeData = nil; //这句代码不能省略，否则在点击继续活着开始的时候会重复下载任务
        
    }else{
        //没有下载任务，那么重新创建下载任务；  部分下载暂停异常 NSURLSessionTaskStateCompleted ，但并没有完成，所以重新下载
        if (!item.downloadTask || item.downloadTask.state == NSURLSessionTaskStateCompleted) {             NSString *url = item.downloadURL;
            if (url.length ==0) return;
            [self.downloadItems removeObjectForKey:url];
            [self createDownloadTaskWithUrl:url delegate:item.delegate];
        }else{
            [item.downloadTask resume];
        }
    }
}


- (void)saveDownloadStatus {
    
    [NSKeyedArchiver archiveRootObject:self.downloadItems toFile:[self getArchiverPathIsDownloaded:false]];
    [NSKeyedArchiver archiveRootObject:self.downloadedItems toFile:[self getArchiverPathIsDownloaded:true]];
}

- (NSString *)getArchiverPathIsDownloaded:(BOOL)isDownloaded {
    NSString *saveDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true).firstObject;
    saveDir = [saveDir stringByAppendingPathComponent:@"YCDownload"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:saveDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:saveDir withIntermediateDirectories:true attributes:nil error:nil];
    }
    saveDir = isDownloaded ? [saveDir stringByAppendingPathComponent:@"YCDownloaded.data"] : [saveDir stringByAppendingPathComponent:@"YCDownloading.data"];
    
    return saveDir;
}

- (BOOL)detectDownloadItemIsFinished:(YCDownloadTask *)item {
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:item.tempPath]) {
        NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:item.tempPath error:nil];
        NSInteger fileSize = dic ? (NSInteger)[dic fileSize] : 0;
        if (fileSize>0 && fileSize == item.fileSize) {
            [[NSFileManager defaultManager] moveItemAtPath:item.tempPath toPath:[YCDownloadTask savePathWithSaveName:item.saveName] error:nil];
            return true;
        }
    }else if (item.fileSize>0 && item.fileSize==item.downloadedSize){
        
        if(!item.resumeData) {
            item.downloadedSize = 0;
            item.downloadTask = nil;
        }
    }
    
    return false;
}

// 部分下载会把域名地址解析成IP地址，所以根据URL获取不到下载任务,所以根据下载文件名称获取(后台下载，重新启动，获取的的url是IP)
- (YCDownloadTask *)getDownloadItemWithUrl:(NSString *)downloadUrl isDownloadList:(BOOL)isDownloadList{
    
    NSMutableDictionary *items = isDownloadList ? self.downloadItems : self.downloadedItems;
    NSString *fileName = downloadUrl.lastPathComponent;
    __block YCDownloadTask *item = nil;
    [items enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        YCDownloadTask *dItem = obj;
        if ([dItem.downloadURL.lastPathComponent isEqualToString:fileName]) {
            item = dItem;
            *stop = true;
        }
    }];
    
    return item;
    
}


#pragma mark -  NSURLSessionDelegate


- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
    NSString *locationString = [location path];
    NSError *error;
    
    NSString *downloadUrl = [YCDownloadTask getURLFromTask:downloadTask];
    YCDownloadTask *item = [self getDownloadItemWithUrl:downloadUrl isDownloadList:true];
    if(!item){
        NSLog(@"download finished , item nil error!!!! url: %@", downloadUrl);
        if ([item.delegate respondsToSelector:@selector(downloadFailed:)]) {
            [item.delegate downloadFailed:item];
        }
        [self saveDownloadStatus];
        return;
    }
    item.tempPath = locationString;
    
    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:locationString error:nil];
    NSInteger fileSize = dic ? (NSInteger)[dic fileSize] : 0;
    
    BOOL isCompltedFile = (fileSize>0) && (fileSize == item.fileSize);
    if (!isCompltedFile) {
        NSLog(@"download finished , file size error!!!! url: %@", downloadUrl);
        [self pauseDownloadTask:item];
        if ([item.delegate respondsToSelector:@selector(downloadFailed:)]) {
            [item.delegate downloadFailed:item];
        }
        item.downloadTask = nil;
        [self saveDownloadStatus];
        return;
    }
    
    [[NSFileManager defaultManager] moveItemAtPath:locationString toPath:[YCDownloadTask savePathWithSaveName:item.saveName] error:&error];

    NSLog(@"downloadTask:%lu didFinishDownloadingToURL:%@      \n---->to Path:  %@", (unsigned long)downloadTask.taskIdentifier, location, [YCDownloadTask savePathWithSaveName:item.saveName]);
    
    if (item.downloadURL.length != 0) {
        [self.downloadedItems setObject:item forKey:item.downloadURL];
        [self.downloadItems removeObjectForKey:item.downloadURL];
    }
    if ([item.delegate respondsToSelector:@selector(downloadFinished:)]) {
        [item.delegate downloadFinished:item];
    }
    item.resumeData = nil;

    [self saveDownloadStatus];
    
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    
    NSLog(@"fileOffset:%lld expectedTotalBytes:%lld",fileOffset,expectedTotalBytes);
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    YCDownloadTask *item = [self getDownloadItemWithUrl:[YCDownloadTask getURLFromTask:downloadTask] isDownloadList:true];
    item.downloadedSize = (NSInteger)totalBytesWritten;
    if (item.fileSize == 0)  {
        [item updateItem];
        if ([item.delegate respondsToSelector:@selector(downloadCreated:)]) {
            [item.delegate downloadCreated:item];
        }
    }
    if ([item.delegate respondsToSelector:@selector(downloadProgress:totalBytesWritten:totalBytesExpectedToWrite:)]){
        [item.delegate downloadProgress:item totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
    
    NSString *url = downloadTask.response.URL.absoluteString;
    NSLog(@"downloadURL: %@  downloadedSize: %zd totalSize: %zd  progress: %f", url, bytesWritten, totalBytesWritten, (float)totalBytesWritten / totalBytesExpectedToWrite);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    
    
    NSLog(@"willPerformHTTPRedirection ------> %@",response);
    
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSLog(@"Background URL session %@ finished events.\n", session);
    
    
}


/*
 * 该方法下载成功和失败都会回调，只是失败的是error是有值的，
 * 在下载失败时，error的userinfo属性可以通过NSURLSessionDownloadTaskResumeData
 * 这个key来取到resumeData(和上面的resumeData是一样的)，再通过resumeData恢复下载
 */
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    
    if (error) {
        @try {
            // check if resume data are available
            NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            YCDownloadTask *item = [self getDownloadItemWithUrl:[YCDownloadTask getURLFromTask:task] isDownloadList:true];
            if (resumeData) {
                //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
                item.resumeData = resumeData;
                //id obj = [NSPropertyListSerialization propertyListWithData:resumeData options:0 format:0 error:nil];
                //NSString *str = [[NSString alloc] initWithData:resumeData encoding:NSUTF8StringEncoding];
                NSLog(@"error ----->   %@     --->%zd", item.downloadURL, resumeData.length);
                
            }else{
                NSLog(@"%@", error);
                if ([item.delegate respondsToSelector:@selector(downloadFailed:)]) {
                    [item.delegate downloadFailed:item];
                }
            }
        } @catch (NSException *exception) {}
    }
}



@end
