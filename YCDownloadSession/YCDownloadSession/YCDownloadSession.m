//
//  YCDownloadSession.m
//  YCDownloadSession
//
//  Created by wangzhen on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "YCDownloadSession.h"

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
            YCDownloadItem *item = [self.downloadItems valueForKey:[YCDownloadItem getURLFromTask:obj]];
            if(!item){
                item = [[YCDownloadItem alloc] init];
                NSAssert(true, @"Exception For Item");
            }
            item.downloadTask = obj;
            [self.downloadItems setObject:item forKey:item.downloadURL];
        }];
        //获取后台下载缓存在本地的数据
        [self.downloadedItems enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, YCDownloadItem *obj, BOOL * _Nonnull stop) {
            if ([[NSFileManager defaultManager] fileExistsAtPath:obj.tempPath]) {
                [[NSFileManager defaultManager] moveItemAtPath:obj.tempPath toPath:obj.savePath error:nil];
                
                NSLog(@"------>>>>>>> file move to ---->>>>>");
            }
        }];
        
        NSLog(@"%@", dictM);
    }
    return self;
}

- (NSURLSession *)getDownloadURLSession {
    
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *identifier = @"cc.onezen.BackgroundSession";
        NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                delegate:self
                                           delegateQueue:[NSOperationQueue mainQueue]];
    });
    
    return session;
}

#pragma mark - event


- (void)startDownloadWithUrl:(NSString *)downloadURLString savePath:(NSString *)savePath{
    YCDownloadItem *item = [self.downloadedItems valueForKey:downloadURLString];
    if (item) {
        if ([self.delegate respondsToSelector:@selector(downloadinished:)]) {
            [self.delegate downloadinished:item];
        }
        return;
    }
    
    item = [self.downloadItems valueForKey:downloadURLString];
    
    if (!item) {
        [self pauseAllDownloadTask];
        NSURL *downloadURL = [NSURL URLWithString:downloadURLString];
        NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
        NSURLSessionDownloadTask *downloadTask = [self.downloadSession downloadTaskWithRequest:request];
        YCDownloadItem *item = [[YCDownloadItem alloc] init];
        item.savePath = savePath;
        item.downloadTask = downloadTask;
        [self.downloadItems setObject:item forKey:item.downloadURL];
        [downloadTask resume];
        [self saveDownloadStatus];
    }else{
        if (item.downloadTask && item.downloadTask.state == NSURLSessionTaskStateRunning && item.resumeData.length == 0) {
            [item.downloadTask resume];
            return;
        }
        [self resumeDownloadTask:item];
    }
    
    
}

- (void)pauseDownloadTask:(YCDownloadItem *)item {
    [item.downloadTask cancelByProducingResumeData:^(NSData * resumeData) {
        if(resumeData.length>0) item.resumeData = resumeData;
        [self saveDownloadStatus];
        NSLog(@"pause ----->   %@     --->%zd", item.downloadURL, resumeData.length);
    }];
}

- (void)pauseDownloadWithUrl:(NSString *)downloadURLString {
    [self pauseDownloadTask:[self.downloadItems valueForKey:downloadURLString]];
    
}
- (void)resumeDownloadWithUrl:(NSString *)downloadURLString {
    [self resumeDownloadTask:[self.downloadItems valueForKey:downloadURLString]];
}


- (void)pauseAllDownloadTask{
    [self.downloadItems enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [self pauseDownloadTask:obj];
    }];
}

- (void)stopDownloadWithItem:(YCDownloadItem *)item {
    
    [item.downloadTask cancel];
}

- (void)stopDownloadWithUrl:(NSString *)downloadURLString {
    [self stopDownloadWithItem:[self.downloadItems valueForKey:downloadURLString]];
    [self.downloadItems removeObjectForKey:downloadURLString];
    [self.downloadedItems removeObjectForKey:downloadURLString];
    [self saveDownloadStatus];
}

- (void)resumeDownloadTask:(YCDownloadItem *)item {
    
    NSData *data = item.resumeData;
    if (data.length > 0) {
        NSURLSessionDownloadTask *downloadTask = [self.downloadSession downloadTaskWithResumeData:data];
        [downloadTask resume];
        if (item.downloadTask) {
            [self pauseDownloadTask:item];
        }
        item.downloadTask = downloadTask;
        item.resumeData = nil; //这句代码不能省略，否则在点击继续活着开始的时候会重复下载任务
        
    }else{
        if (!item.downloadTask) { //没有下载任务，那么重新创建下载任务
            NSString *url = item.downloadURL;
            [self.downloadItems removeObjectForKey:url];
            [self startDownloadWithUrl:url savePath:item.savePath];
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


#pragma mark -  NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
    NSString *locationString = [location path];
    NSError *error;
    YCDownloadItem *item = [self.downloadItems valueForKey:[YCDownloadItem getURLFromTask:downloadTask]];
    item.tempPath = locationString;
    [self.downloadItems removeObjectForKey:item.downloadURL];
    item.resumeData = nil;
    [self.downloadedItems setObject:item forKey:item.downloadURL];
    [[NSFileManager defaultManager] moveItemAtPath:locationString toPath:item.savePath error:&error];
    if (error) {
        NSLog(@"download finished , and move file failed!!  ----->>>>>%@", error);
    }
    NSLog(@"downloadTask:%lu didFinishDownloadingToURL:%@      \n---->to Path:  %@", (unsigned long)downloadTask.taskIdentifier, location, item.savePath);
   
    if ([self.delegate respondsToSelector:@selector(downloadinished:)]) {
        [self.delegate downloadinished:item];
    }
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
    
    YCDownloadItem *item = [self.downloadItems valueForKey:[YCDownloadItem getURLFromTask:downloadTask]];
    item.downloadedSize = (NSInteger)totalBytesWritten;
    if (!item.response)  [item updateItem];
    if ([self.delegate respondsToSelector:@selector(downloadProgress:totalBytesWritten:totalBytesExpectedToWrite:)]){
        [self.delegate downloadProgress:item totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
    
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    
    
    NSLog(@"willPerformHTTPRedirection ------> %@",response);
    
}

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    NSLog(@"Background URL session %@ finished events.\n", session);
    
//    if (session.configuration.identifier) {
//        AppDelegate *del = [AppDelegate sharedDelegate];
//        [del callCompletionHandlerForSession:self.downloadSession.configuration.identifier];
//    }
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
        // check if resume data are available
        NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        YCDownloadItem *item = [self.downloadItems valueForKey:[YCDownloadItem getURLFromTask:task]];
        if (resumeData) {
            //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
           
            item.resumeData = resumeData;
            NSString *str = [[NSString alloc] initWithData:resumeData encoding:NSUTF8StringEncoding];
            
            NSLog(@"error ----->   %@     --->%zd   ---> %@", item.downloadURL, resumeData.length, str);
            
            
        }else{
            if ([self.delegate respondsToSelector:@selector(downloadFailed:)]) {
                [self.delegate downloadFailed:item];
            }
        }
    }
}

@end
