//
//  YCDownloadSession.m
//  YCDownloadSession
//
//  Created by wangzhen on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "YCDownloadSession.h"

@interface YCDownloadSession ()<NSURLSessionDelegate>

@property (nonatomic, strong) NSURLSession *downloadSession;
@property (nonatomic, strong) NSMutableDictionary *tasks;
@property (nonatomic, strong) NSMutableDictionary *resumeData;

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
        self.downloadSession = [self getDownloadURLSession];
        NSMutableDictionary *dictM = [self.downloadSession valueForKey:@"tasks"];
        self.tasks = [NSMutableDictionary dictionary];
        self.resumeData = [NSMutableDictionary dictionary];
        [dictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [self.tasks setValue:obj forKey:[self getURLFromTask:obj]];
            [self pauseDownloadTask:obj];
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
        NSString *identifier = @"com.yourcompany.appId.BackgroundSession";
        NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
        session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                delegate:self
                                           delegateQueue:[NSOperationQueue mainQueue]];
    });
    
    return session;
}

#pragma mark - event


- (NSString *)getURLFromTask:(NSURLSessionTask *)task {
    NSURLRequest *req = [task currentRequest];
    return req.URL.absoluteString;
}

- (void)startDownloadWithUrl:(NSString *)downloadURLString {
    
    NSURLSessionDownloadTask *downloadTask = [self.tasks valueForKey:downloadURLString];
    
    if (!downloadTask) {
        [self pauseAllDownloadTask];
        NSURL *downloadURL = [NSURL URLWithString:downloadURLString];
        NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
        downloadTask = [self.downloadSession downloadTaskWithRequest:request];
        [self.tasks setValue:downloadTask forKey:downloadURLString];
        [downloadTask resume];
    }else{
        [self resumeDownloadTask:downloadTask];
    }
    
    
}

- (void)pauseDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    
    __weak __typeof(self) wSelf = self;
    
    [downloadTask cancelByProducingResumeData:^(NSData * resumeData) {
        [wSelf.resumeData setValue:resumeData forKey:[self getURLFromTask:downloadTask]];
        
    }];
}

- (void)pauseDownloadWithUrl:(NSString *)downloadURLString {
    [self pauseDownloadTask:[self.tasks valueForKey:downloadURLString]];
    
}
- (void)resumeDownloadWithUrl:(NSString *)downloadURLString {
    [self resumeDownloadTask:[self.tasks valueForKey:downloadURLString]];
}


- (void)pauseAllDownloadTask{
    [self.tasks enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [self pauseDownloadTask:obj];
    }];
}

- (void)stopDownloadWithUrl:(NSString *)downloadURLString {
    
}

- (void)resumeDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    
    NSData *data = [self.resumeData valueForKey:[self getURLFromTask:downloadTask]];
    if (data.length > 0) {
        NSURLSessionDownloadTask *downloadTask = nil;
        downloadTask = [self.downloadSession downloadTaskWithResumeData:data];
        [downloadTask resume];
        [self.tasks setValue:downloadTask forKey:[self getURLFromTask:downloadTask]];
        [self.resumeData removeObjectForKey:[self getURLFromTask:downloadTask]];
    }else{
        [downloadTask resume];
    }
}

#pragma mark -  NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
    NSLog(@"downloadTask:%lu didFinishDownloadingToURL:%@", (unsigned long)downloadTask.taskIdentifier, location);
    NSString *locationString = [location path];
    NSError *error;
     NSString *finalLocation = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"%lufile",(unsigned long)downloadTask.taskIdentifier]];
    NSString *savePath = self.savePath.length > 0 ? self.savePath : finalLocation;
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
    
    NSLog(@"downloadTask:%lu percent:%.2f%%",(unsigned long)downloadTask.taskIdentifier,(float)totalBytesWritten / totalBytesExpectedToWrite * 100);
    
    if ([self.delegate respondsToSelector:@selector(request:totalBytesWritten:totalBytesExpectedToWrite:)]){
        [self.delegate request:self totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    }
    
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
        if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
            NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
            [self.resumeData setValue:resumeData forKey:[self getURLFromTask:task]];
        }
    } else {
        
    }
}

#pragma mark - others



@end
