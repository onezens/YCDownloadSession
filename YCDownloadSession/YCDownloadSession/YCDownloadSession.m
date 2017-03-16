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
        if(!self.downloadedItems) self.downloadedItems = [NSMutableDictionary dictionary];
        if(!self.downloadItems) self.downloadItems = [NSMutableDictionary dictionary];
        [dictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            YCDownloadItem *item = [self.downloadItems valueForKey:[YCDownloadItem getURLFromTask:obj]];
            if(!item) item = [[YCDownloadItem alloc] init];
            item.downloadTask = obj;
            [self.downloadItems setObject:item forKey:item.downloadURL];
//            [self pauseDownloadTask:item];
//
        }];
        [self pauseAllDownloadTask];
        [self.downloadItems enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self resumeDownloadTask:obj];
            });
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


- (void)startDownloadWithUrl:(NSString *)downloadURLString {
    
    YCDownloadItem *item = [self.downloadItems valueForKey:downloadURLString];
   
    if (!item) {
        [self pauseAllDownloadTask];
        NSURL *downloadURL = [NSURL URLWithString:downloadURLString];
        NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
        NSURLSessionDownloadTask *downloadTask = [self.downloadSession downloadTaskWithRequest:request];
        YCDownloadItem *item = [[YCDownloadItem alloc] init];
        item.downloadTask = downloadTask;
        [self.downloadItems setObject:item forKey:item.downloadURL];
        [downloadTask resume];
    }else{
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

- (void)stopDownloadWithUrl:(NSString *)downloadURLString {
    [self saveDownloadStatus];
}

- (void)resumeDownloadTask:(YCDownloadItem *)item {
    
    NSData *data = item.resumeData;
    if (data.length > 0) {
        NSURLSessionDownloadTask *downloadTask = [self.downloadSession downloadTaskWithResumeData:data];
        [downloadTask resume];
        item.downloadTask = downloadTask;
        item.resumeData = nil; //这句代码不能省略，否则在点击继续活着开始的时候会重复下载任务
        
        NSLog(@"resume  1");
    }else{
        
//        NSURLSessionTaskStateRunning = 0,                     /* The task is currently being serviced by the session */
//        NSURLSessionTaskStateSuspended = 1,
//        NSURLSessionTaskStateCanceling = 2,                   /* The task has been told to cancel.  The session will receive a URLSession:task:didCompleteWithError: message. */
//        NSURLSessionTaskStateCompleted = 3,
        NSLog(@"----->>> state  -------->>>>>%ld", (long)item.downloadTask.state);
        if (!item.downloadTask || item.downloadTask.state == NSURLSessionTaskStateCompleted) {
            NSString *url = item.downloadURL;
            [self.downloadItems removeObjectForKey:url];
            [self startDownloadWithUrl:url];
                    NSLog(@"resume  2");
        }else{
             [item.downloadTask resume];
                    NSLog(@"resume  3");
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
    
    NSLog(@"downloadTask:%lu didFinishDownloadingToURL:%@", (unsigned long)downloadTask.taskIdentifier, location);
    NSString *locationString = [location path];
    NSError *error;
    NSString *finalLocation = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%lufile",(unsigned long)downloadTask.taskIdentifier]];
    YCDownloadItem *item = [self.downloadItems valueForKey:[YCDownloadItem getURLFromTask:downloadTask]];
    [self.downloadItems removeObjectForKey:item.downloadURL];
    item.resumeData = nil;
    [self.downloadedItems setObject:item forKey:item.downloadURL];
    NSString *savePath =  item.savePath.length > 0 ? item.savePath : finalLocation;
    [[NSFileManager defaultManager] moveItemAtPath:locationString toPath:savePath error:&error];
    if ([self.delegate respondsToSelector:@selector(requestFinished:)]) {
        [self.delegate requestFinished:self];
    }
    // 用 NSFileManager 将文件复制到应用的存储中
    // ...
    
    // 通知 UI 刷新
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
    
//    NSLog(@"downloadTask:%lu percent:%.2f%%",(unsigned long)downloadTask.taskIdentifier,(float)totalBytesWritten / totalBytesExpectedToWrite * 100);
    YCDownloadItem *item = [self.downloadItems valueForKey:[YCDownloadItem getURLFromTask:downloadTask]];
    if (!item.response)  [item updateItem];
    if ([self.delegate respondsToSelector:@selector(request:totalBytesWritten:totalBytesExpectedToWrite:)]){
        [self.delegate request:self totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
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
    
    if (session.configuration.identifier) {
        // 调用在 -application:handleEventsForBackgroundURLSession: 中保存的 handler
        //        [self callCompletionHandlerForSession:session.configuration.identifier];
        
    }
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
        if ([self.delegate respondsToSelector:@selector(requestFailed:)]) {
            [self.delegate requestFailed:self];
        }
        // check if resume data are available
        NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        if (resumeData) {
            //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
            YCDownloadItem *item = [self.downloadItems valueForKey:[YCDownloadItem getURLFromTask:task]];
            item.resumeData = resumeData;
            NSLog(@"error ----->   %@     --->%zd", item.downloadURL, resumeData.length);

        }
    } else {
        
    }
}

#pragma mark - others



@end
