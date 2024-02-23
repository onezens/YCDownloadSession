//
//  YCDownloadSession.m
//  Pods-YCDownloadSession
//
//  Created by wz on 2022/2/25.
//

#import "YCDownloadSession.h"
#import "NSURLSessionTask+YCDownload.h"

@interface YCDownloadTask(Session)

@property (nonatomic, assign, readwrite) YCDownloadTaskState state;

- (void)buildTaskWithSession:(NSURLSession *)session request:(NSURLRequest *)request;

@end

@interface YCDownloadSession () <NSURLSessionDelegate>

@property (nonatomic, strong) YCDownloadSessionConfig *config;

@property (nonatomic, strong) NSURLSession *urlSession;

@end

@implementation YCDownloadSession

#pragma mark - public

+ (instancetype)sharedSession
{
    static dispatch_once_t onceToken;
    static YCDownloadSession *_session;
    dispatch_once(&onceToken, ^{
        YCDownloadSessionConfig *config = [YCDownloadSessionConfig new];
        _session = [YCDownloadSession sessionWithConfiguration:config];
    });
    return _session;
}

+ (instancetype)sessionWithConfiguration:(YCDownloadSessionConfig *)config
{
    YCDownloadSession *session = [YCDownloadSession new];
    session.config = config;
    NSURLSessionConfiguration *urlSessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:config.identifier];
    session.urlSession = [NSURLSession sessionWithConfiguration:urlSessionConfig delegate:session delegateQueue:config.queue];
    return session;
}

- (YCDownloadTask *)taskWithURL:(NSURL *)URL
{
    return [self taskWithRequest:[NSURLRequest requestWithURL:URL]];
}

- (YCDownloadTask *)taskWithUrlStr:(NSString *)url
{
    return [self taskWithURL:[NSURL URLWithString:url]];
}

- (YCDownloadTask *)taskWithRequest:(NSURLRequest *)request
{
    YCDownloadTask *task = [YCDownloadTask new];
    [task buildTaskWithSession:self.urlSession request:request];
    return task;
}

#pragma mark - NSURLSession delegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
//    if (self.isNeedCreateSession) {
//        self.isNeedCreateSession = false;
//        [self recreateSession];
//        if (_bgRCSBlock) {
//            _bgRCSBlock();
//            _bgRCSBlock = nil;
//        }
//    }
}

//- (NSInteger)statusCodeWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
//    if ([downloadTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
//        NSHTTPURLResponse *response = (NSHTTPURLResponse *)downloadTask.response;
//        return response.statusCode;
//    }
//    return -1;
//}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location 
{
    
    if (!downloadTask.ycTask) {
        //TODO: Cache
        return;
    }
    
    downloadTask.ycTask.state = YCDownloadTaskStateCompleted;
    if (!downloadTask.ycTask.completionBlock) {
        return;
    }
    
    downloadTask.ycTask.completionBlock(location, nil);
    

//    YCDownloadTask *task = [self taskWithSessionTask:downloadTask];
//
//    NSInteger statusCode = [self statusCodeWithDownloadTask:downloadTask];
//    if (!(statusCode == 200 || statusCode == 206)) {
//        task.downloadedSize = 0;
//        NSLog(@"[didFinishDownloadingToURL] http status code error: %ld", (long)statusCode);
//        NSError *error = [NSError errorWithDomain:@"http status code error" code:11002 userInfo:nil];
//        [self completionDownloadTask:task localPath:nil error:error];
//        return;
//    }
//    
//    NSString *localPath = [location path];
//    if (task.fileSize==0) [task updateTask];
//    int64_t fileSize = [YCDownloadUtils fileSizeWithPath:localPath];
//    NSError *error = nil;
//    if (fileSize>0 && fileSize != task.fileSize) {
//        NSString *errStr = [NSString stringWithFormat:@"[YCDownloader didFinishDownloadingToURL] fileSize Error, task fileSize: %lld tmp fileSize: %lld", task.fileSize, fileSize];
//        NSLog(@"%@",errStr);
//        error = [NSError errorWithDomain:errStr code:11001 userInfo:nil];
//        localPath = nil;
//    }else{
//        task.downloadedSize = fileSize;
//    }
//    [self completionDownloadTask:task localPath:localPath error:error];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite 
{
    downloadTask.ycTask.state = YCDownloadTaskStateRunning;
    if (downloadTask.ycTask.progressBlock) {
        float progress = (float)totalBytesWritten / totalBytesExpectedToWrite;
        downloadTask.ycTask.progressBlock(progress);
    }
    
//    NSInteger statusCode = [self statusCodeWithDownloadTask:downloadTask];
//    if (!(statusCode == 200 || statusCode == 206)) {
//        return;
//    }
//    YCDownloadTask *task = [self taskWithSessionTask:downloadTask];
//    if (!task) {
//        [downloadTask cancel];
//        NSAssert(false,@"didWriteData task nil!");
//    }
//    task.downloadedSize = totalBytesWritten;
//    if(task.fileSize==0) [task updateTask];
//    task.progress.totalUnitCount = totalBytesExpectedToWrite>0 ? totalBytesExpectedToWrite : task.fileSize;
//    task.progress.completedUnitCount = totalBytesWritten;
//    if(task.progressHandler) task.progressHandler(task.progress, task);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionDownloadTask *)downloadTask didCompleteWithError:(NSError *)error 
{
    
    if (!downloadTask.ycTask) {
        //TODO: Cache
        return;
    }
    
    downloadTask.ycTask.state = YCDownloadTaskStateCompleted;
    if (!downloadTask.ycTask.completionBlock) {
        return;
    }
    
    downloadTask.ycTask.completionBlock(nil, error);
    
//    if (!error) return;
//    YCDownloadTask *task = [self taskWithSessionTask:downloadTask];
//    if(task.isDeleted) return;
//    // check whether resume data are available
//    NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
//    if (resumeData) {
//        //can resume
//        if (YC_DEVICE_VERSION >= 11.0f && YC_DEVICE_VERSION < 11.2f) {
//            //修正iOS11 多次暂停继续 文件大小不对的问题
//            resumeData = [YCResumeData cleanResumeData:resumeData];
//        }
//        //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
//        task.resumeData = resumeData;
//        id resumeDataObj = [NSPropertyListSerialization propertyListWithData:resumeData options:0 format:0 error:nil];
//        if ([resumeDataObj isKindOfClass:[NSDictionary class]]) {
//            NSDictionary *resumeDict = resumeDataObj;
//            task.tmpName = [resumeDict valueForKey:@"NSURLSessionResumeInfoTempFileName"];
//        }
//        task.resumeData = resumeData;
//        [self saveDownloadTask:task];
//        [self removeMembCacheTask:downloadTask task:task];
//        task.downloadTask = nil;
//    }else{
//        //cannot resume
//        NSLog(@"[didCompleteWithError] : %@",error);
//        [self completionDownloadTask:task localPath:nil error:error];
//    }
}

@end
