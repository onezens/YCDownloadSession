//
//  YCDownloadSession.m
//  YCDownloadSession
//
//  Created by wz on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Github: https://github.com/onezens/YCDownloadSession
//

#import "YCDownloadSession.h"
#import "NSURLSession+CorrectedResumeData.h"

#define IS_IOS10ORLATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10)
static NSString * const kIsAllowCellar = @"kIsAllowCellar";
@interface YCDownloadSession ()<NSURLSessionDownloadDelegate>

/**正在下载的task*/
@property (nonatomic, strong) NSMutableDictionary *downloadTasks;
/**下载完成的task*/
@property (nonatomic, strong) NSMutableDictionary *downloadedTasks;
/**后台下载回调的handlers，所有的下载任务全部结束后调用*/
@property (nonatomic, copy) BGCompletedHandler completedHandler;
@property (nonatomic, strong, readonly) NSURLSession *downloadSession;
/**重新创建sessio标记位*/
@property (nonatomic, assign) BOOL isNeedCreateSession;
/**启动下一个下载任务的标记位*/
@property (nonatomic, assign) BOOL isStartNextTask;

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
        //初始化
        _downloadSession = [self getDownloadURLSession];
        _maxTaskCount = 1;
        self.downloadTasks = [NSKeyedUnarchiver unarchiveObjectWithFile:[self getArchiverPathIsDownloaded:false]];
        self.downloadedTasks = [NSKeyedUnarchiver unarchiveObjectWithFile:[self getArchiverPathIsDownloaded:true]];
        
        //获取保存在本地的数据是否为空，为空则初始化
        if(!self.downloadedTasks) self.downloadedTasks = [NSMutableDictionary dictionary];
        if(!self.downloadTasks) self.downloadTasks = [NSMutableDictionary dictionary];
        
        //获取背景session正在运行的(app重启，或者闪退会有任务)
        NSMutableDictionary *dictM = [self.downloadSession valueForKey:@"tasks"];
        [dictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            YCDownloadTask *task = [self getDownloadTaskWithUrl:[YCDownloadTask getURLFromTask:obj] isDownloadingList:true];
            if(!task){
                [obj cancel];
            }else{
                task.downloadTask = obj;
            }
        }];
        
        //app重启，或者闪退的任务全部暂停
        [self pauseAllDownloadTask];
        
    }
    return self;
}

- (NSURLSession *)getDownloadURLSession {
    
    NSURLSession *session = nil;
    NSString *identifier = [self backgroundSessionIdentifier];
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
    sessionConfig.allowsCellularAccess = [[NSUserDefaults standardUserDefaults] boolForKey:kIsAllowCellar];
    session = [NSURLSession sessionWithConfiguration:sessionConfig
                                            delegate:self
                                       delegateQueue:[NSOperationQueue mainQueue]];
    return session;
}

- (NSString *)backgroundSessionIdentifier {
    NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSString *identifier = [NSString stringWithFormat:@"%@.BackgroundSession", bundleId];
    return identifier;
}


- (void)recreateSession {
    
    _downloadSession = [self getDownloadURLSession];
    NSLog(@"recreate Session success");
    //恢复正在下载的task状态
    [self.downloadTasks enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        YCDownloadTask *task = obj;
        task.downloadTask = nil;
        if (task.needToRestart) {
            task.needToRestart = false;
            [self resumeDownloadTask:task];
        }
    }];
}


-(void)setMaxTaskCount:(NSInteger)maxTaskCount {
    if (maxTaskCount>3) {
        _maxTaskCount = 3;
    }else if(maxTaskCount <= 0){
        _maxTaskCount = 1;
    }else{
        _maxTaskCount = maxTaskCount;
    }
}

- (NSInteger)currentTaskCount {
    NSMutableDictionary *dictM = [self.downloadSession valueForKey:@"tasks"];
    __block NSInteger count = 0;
    [dictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSURLSessionTask *task = obj;
        if (task.state == NSURLSessionTaskStateRunning) {
            count++;
        }
    }];
    
    return count;
}

#pragma mark - public


- (void)startDownloadWithUrl:(NSString *)downloadURLString delegate:(id<YCDownloadTaskDelegate>)delegate saveName:(NSString *)saveName{
    if (downloadURLString.length == 0)  return;
    
    //判断是否是下载完成的任务
    YCDownloadTask *task = [self getDownloadTaskWithUrl:downloadURLString isDownloadingList:false];
    if (task) {
        task.delegate = delegate;
        [self downloadStatusChanged:YCDownloadStatusFinished task:task];
        return;
    }
    //读取正在下载的任务
    task = [self getDownloadTaskWithUrl:downloadURLString isDownloadingList:true];
    
    if (!task) {
        //判断任务的个数，如果达到最大值则返回，回调等待
        if([self currentTaskCount] >= self.maxTaskCount){
            //创建任务，让其处于等待状态
            [self createDownloadTaskItemWithUrl:downloadURLString delegate:delegate saveName:saveName];
            [self downloadStatusChanged:YCDownloadStatusWaiting task:task];
        }else {
            //开始下载
            [self createDownloadTaskWithUrl:downloadURLString delegate:delegate saveName:saveName];
        }
    }else{
        task.delegate = delegate;
        if ([self detectDownloadTaskIsFinished:task]) {
            [self downloadStatusChanged:YCDownloadStatusFinished task:task];
            return;
        }
        
        if (task.downloadTask && task.downloadTask.state == NSURLSessionTaskStateRunning && task.resumeData.length == 0) {
            [task.downloadTask resume];
            [self downloadStatusChanged:YCDownloadStatusDownloading task:task];
            return;
        }
        [self resumeDownloadTask:task];
    }
}

- (void)pauseDownloadWithUrl:(NSString *)downloadURLString {
    self.isStartNextTask = true;
    [self pauseDownloadTask:[self getDownloadTaskWithUrl:downloadURLString isDownloadingList:true]];
}

- (void)pauseAllDownloadTask{
    [self.downloadTasks enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [self pauseDownloadTask:obj];
    }];
}

- (void)resumeDownloadWithUrl:(NSString *)downloadURLString delegate:(id<YCDownloadTaskDelegate>)delegate saveName:(NSString *)saveName{
    //判断是否是下载完成的任务
    YCDownloadTask *task = [self getDownloadTaskWithUrl:downloadURLString isDownloadingList:false];
    if (task) {
        task.delegate = delegate;
        [self downloadStatusChanged:YCDownloadStatusFinished task:task];
        return;
    }
    task = [self getDownloadTaskWithUrl:downloadURLString isDownloadingList:true];
    
    //如果下载列表和下载完成列表都不存在，则重新创建
    if (!task) {
        [self startDownloadWithUrl:downloadURLString delegate:delegate saveName:nil];
        return;
    }
    
    if(delegate) task.delegate = delegate;
    [self resumeDownloadTask: task];
}

- (void)stopDownloadWithUrl:(NSString *)downloadURLString {
    @try {
        [self stopDownloadWithTask:[self getDownloadTaskWithUrl:downloadURLString isDownloadingList:true]];
        [self.downloadTasks removeObjectForKey:downloadURLString];
        [self.downloadedTasks removeObjectForKey:downloadURLString];
    } @catch (NSException *exception) {  }
    [self saveDownloadStatus];
    [self startNextDownloadTask];
}

- (void)allowsCellularAccess:(BOOL)isAllow {
    
    [[NSUserDefaults standardUserDefaults] setBool:isAllow forKey:kIsAllowCellar];
    [self.downloadTasks enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        YCDownloadTask *task = obj;
        if (task.downloadTask.state == NSURLSessionTaskStateRunning) {
            task.needToRestart = true;
            [self pauseDownloadTask:task];
        }
    }];

    [_downloadSession invalidateAndCancel];
    self.isNeedCreateSession = true;
}

- (BOOL)isAllowsCellularAccess {
    
    return [[NSUserDefaults standardUserDefaults] boolForKey:kIsAllowCellar];
}

-(void)addCompletionHandler:(BGCompletedHandler)handler identifier:(NSString *)identifier{
    if ([[self backgroundSessionIdentifier] isEqualToString:identifier]) {
        self.completedHandler = handler;
    }
}

#pragma mark - private

- (void)createDownloadTaskWithUrl:(NSString *)downloadURLString delegate:(id<YCDownloadTaskDelegate>)delegate saveName:(NSString *)saveName{
    
    NSURL *downloadURL = [NSURL URLWithString:downloadURLString];
    NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
    NSURLSessionDownloadTask *downloadTask = [self.downloadSession downloadTaskWithRequest:request];
    YCDownloadTask *task = [self createDownloadTaskItemWithUrl:downloadURLString delegate:delegate saveName:saveName];
    task.downloadTask = downloadTask;
    [downloadTask resume];
    [self downloadStatusChanged:YCDownloadStatusDownloading task:task];
}

- (YCDownloadTask *)createDownloadTaskItemWithUrl:(NSString *)downloadURLString delegate:(id<YCDownloadTaskDelegate>)delegate saveName:(NSString *)saveName{
    
    YCDownloadTask *task = [[YCDownloadTask alloc] initWithSaveName:saveName];
    task.downloadURL = downloadURLString;
    task.delegate = delegate;
    [self.downloadTasks setObject:task forKey:task.downloadURL];
    [self downloadStatusChanged:YCDownloadStatusWaiting task:task];
    return task;
}

- (void)pauseDownloadTask:(YCDownloadTask *)task{
    [task.downloadTask cancelByProducingResumeData:^(NSData * resumeData) {
        NSLog(@"pause ----->   %zd  ----->   %@", resumeData.length, task.downloadURL);
        if(resumeData.length>0) task.resumeData = resumeData;
        task.downloadTask = nil;
        [self saveDownloadStatus];
        [self downloadStatusChanged:YCDownloadStatusPaused task:task];
        if (self.isStartNextTask) {
            [self startNextDownloadTask];
        }
    }];
}


- (void)resumeDownloadTask:(YCDownloadTask *)task {
    
    if(!task) return;
    if (([self currentTaskCount] >= self.maxTaskCount) && task.downloadStatus != YCDownloadStatusDownloading) {
        [self downloadStatusChanged:YCDownloadStatusWaiting task:task];
        return;
    }
    if ([self detectDownloadTaskIsFinished:task]) {
        [self downloadStatusChanged:YCDownloadStatusFinished task:task];
        return;
    }
    
    NSData *data = task.resumeData;
    if (data.length > 0) {
        if(task.downloadTask && task.downloadTask.state == NSURLSessionTaskStateRunning){
            [self downloadStatusChanged:YCDownloadStatusDownloading task:task];
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
        task.downloadTask = downloadTask;
        [downloadTask resume];
        task.resumeData = nil;
        [self downloadStatusChanged:YCDownloadStatusDownloading task:task];
        
    }else{
        //没有下载任务，那么重新创建下载任务；  部分下载暂停异常 NSURLSessionTaskStateCompleted ，但并没有完成，所以重新下载
        if (!task.downloadTask || task.downloadTask.state == NSURLSessionTaskStateCompleted) {
            NSString *url = task.downloadURL;
            if (url.length ==0) return;
            [self.downloadTasks removeObjectForKey:url];
            [self createDownloadTaskWithUrl:url delegate:task.delegate saveName:task.saveName];
        }else{
            [task.downloadTask resume];
            [self downloadStatusChanged:YCDownloadStatusDownloading task:task];
        }
    }
}


- (void)stopDownloadWithTask:(YCDownloadTask *)task {
    [task.downloadTask cancel];
}

- (void)startNextDownloadTask {
    self.isStartNextTask = false;
    if ([self currentTaskCount] < self.maxTaskCount) {
        [self.downloadTasks enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            YCDownloadTask *task = obj;
            if ((!task.downloadTask || task.downloadTask.state != NSURLSessionTaskStateRunning) && task.downloadStatus == YCDownloadStatusWaiting) {
                [self resumeDownloadTask:task];
            }
        }];
    }
}


- (void)downloadStatusChanged:(YCDownloadStatus)status task:(YCDownloadTask *)task{
    
    task.downloadStatus = status;
    [self saveDownloadStatus];
    switch (status) {
        case YCDownloadStatusWaiting:
            break;
        case YCDownloadStatusDownloading:
            break;
        case YCDownloadStatusPaused:
            break;
        case YCDownloadStatusFailed:
            break;
        case YCDownloadStatusFinished:
            [self startNextDownloadTask];
            break;
        default:
            break;
    }
    
    if ([task.delegate respondsToSelector:@selector(downloadStatusChanged:downloadTask:)]) {
        [task.delegate downloadStatusChanged:status downloadTask:task];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadStatusChangedNoti object:nil];
    
    //等task delegate方法执行完成后去判断该逻辑
    //URLSessionDidFinishEventsForBackgroundURLSession 方法在后台执行一次，所以在此判断执行completedHandler
    if (status == YCDownloadStatusFinished) {
        
        if ([self allTaskFinised]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadAllTaskFinishedNoti object:nil];
            //所有的任务执行结束之后调用completedHanlder
            if (self.completedHandler) {
                NSLog(@"completedHandler");
                self.completedHandler();
                self.completedHandler = nil;
            }
        }

    }
}

- (BOOL)allTaskFinised {
    
    if (self.downloadTasks.count == 0) return true;
    
    __block BOOL isFinished = true;
    [self.downloadTasks enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        YCDownloadTask *task = obj;
        if (task.downloadStatus == YCDownloadStatusWaiting || task.downloadStatus == YCDownloadStatusDownloading) {
            isFinished = false;
            *stop = true;
        }
    }];
    return isFinished;
}


#pragma mark - event

- (void)saveDownloadStatus {
    
    [NSKeyedArchiver archiveRootObject:self.downloadTasks toFile:[self getArchiverPathIsDownloaded:false]];
    [NSKeyedArchiver archiveRootObject:self.downloadedTasks toFile:[self getArchiverPathIsDownloaded:true]];
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

- (BOOL)detectDownloadTaskIsFinished:(YCDownloadTask *)task {
    
    NSMutableArray *tmpPaths = [NSMutableArray array];
    
    if (task.tempPath.length > 0) [tmpPaths addObject:task.tempPath];
    
    if (task.tmpName.length > 0) {
        [tmpPaths addObject:[NSTemporaryDirectory() stringByAppendingPathComponent:task.tmpName]];
        NSString *downloadPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true).firstObject;
        NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
        downloadPath = [downloadPath stringByAppendingPathComponent: [NSString stringWithFormat:@"/com.apple.nsurlsessiond/Downloads/%@/", bundleId]];
        downloadPath = [downloadPath stringByAppendingPathComponent:task.tmpName];
        [tmpPaths addObject:downloadPath];
    }
    
    __block BOOL isFinished = false;
    [tmpPaths enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *path = obj;
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
            NSInteger fileSize = dic ? (NSInteger)[dic fileSize] : 0;
            if (fileSize>0 && fileSize == task.fileSize) {
                [[NSFileManager defaultManager] moveItemAtPath:path toPath:[YCDownloadTask savePathWithSaveName:task.saveName] error:nil];
                isFinished = true;
                task.downloadStatus = YCDownloadStatusFinished;
                *stop = true;
            }
        }
    }];
    
    return isFinished;
}


- (YCDownloadTask *)getDownloadTaskWithUrl:(NSString *)downloadUrl isDownloadingList:(BOOL)isDownloadList{
    
    NSMutableDictionary *tasks = isDownloadList ? self.downloadTasks : self.downloadedTasks;
    __block YCDownloadTask *task = nil;
    [tasks enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        YCDownloadTask *dTask = obj;
        if ([dTask.downloadURL isEqualToString:downloadUrl]) {
            task = dTask;
            *stop = true;
        }
    }];
    return task;
}


#pragma mark -  NSURLSessionDelegate

//将一个后台session作废完成后的回调，用来切换是否允许使用蜂窝煤网络，重新创建session
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
    
    if (self.isNeedCreateSession) {
        self.isNeedCreateSession = false;
        [self recreateSession];
    }
}

//如果appDelegate实现下面的方法，后台下载完成时，会自动唤醒启动app。如果不实现，那么后台下载完成不唤醒，用户手动启动会调用相关回调方法
//-[AppDelegate application:handleEventsForBackgroundURLSession:completionHandler:]
//后台唤醒调用顺序： appdelegate ——> didFinishDownloadingToURL  ——> URLSessionDidFinishEventsForBackgroundURLSession
//手动启动调用顺序: didFinishDownloadingToURL  ——> URLSessionDidFinishEventsForBackgroundURLSession
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
    NSLog(@"%s", __func__);
    
    NSString *locationString = [location path];
    NSError *error;
    
    NSString *downloadUrl = [YCDownloadTask getURLFromTask:downloadTask];
    YCDownloadTask *task = [self getDownloadTaskWithUrl:downloadUrl isDownloadingList:true];
    if(!task){
        NSLog(@"download finished , item nil error!!!! url: %@", downloadUrl);
        return;
    }
    task.tempPath = locationString;
    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:locationString error:nil];
    NSInteger fileSize = dic ? (NSInteger)[dic fileSize] : 0;
    
    //校验文件大小
    BOOL isCompltedFile = (fileSize>0) && (fileSize == task.fileSize);
    if (!isCompltedFile) {
        //文件大小不对，从头开始下载
        [self downloadStatusChanged:YCDownloadStatusFinished task:task];
        return;
    }
    task.downloadedSize = task.fileSize;
    [[NSFileManager defaultManager] moveItemAtPath:locationString toPath:[YCDownloadTask savePathWithSaveName:task.saveName] error:&error];

    if (task.downloadURL.length != 0) {
        [self.downloadedTasks setObject:task forKey:task.downloadURL];
        [self.downloadTasks removeObjectForKey:task.downloadURL];
    }
    [self downloadStatusChanged:YCDownloadStatusFinished task:task];
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
 didResumeAtOffset:(int64_t)fileOffset
expectedTotalBytes:(int64_t)expectedTotalBytes {
    
    //NSLog(@"fileOffset:%lld expectedTotalBytes:%lld",fileOffset,expectedTotalBytes);
}

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    YCDownloadTask *task = [self getDownloadTaskWithUrl:[YCDownloadTask getURLFromTask:downloadTask] isDownloadingList:true];
    task.downloadedSize = (NSInteger)totalBytesWritten;
    if (task.fileSize == 0)  {
        [task updateTask];
        if ([task.delegate respondsToSelector:@selector(downloadCreated:)]) {
            [task.delegate downloadCreated:task];
        }
        [self saveDownloadStatus];
    }
    
    if([task.delegate respondsToSelector:@selector(downloadProgress:downloadedSize:fileSize:)]){
        [task.delegate downloadProgress:task downloadedSize:task.downloadedSize fileSize:task.fileSize];
    }
    
    NSString *url = downloadTask.response.URL.absoluteString;
    NSLog(@"downloadURL: %@  downloadedSize: %zd totalSize: %zd  progress: %f", url, task.downloadedSize, task.fileSize, (float)task.downloadedSize / task.fileSize);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
willPerformHTTPRedirection:(NSHTTPURLResponse *)response
        newRequest:(NSURLRequest *)request
 completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    
    //NSLog(@"willPerformHTTPRedirection ------> %@",response);
}

//后台下载完成后调用。在执行 URLSession:downloadTask:didFinishDownloadingToURL: 之后调用
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    //NSLog(@"%s", __func__);

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
        YCDownloadTask *yctask = [self getDownloadTaskWithUrl:[YCDownloadTask getURLFromTask:task] isDownloadingList:true];
        NSLog(@"error ----->   %@  ----->   %@   --->%zd",error, yctask.downloadURL, resumeData.length);
        if (resumeData) {
            //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
            yctask.resumeData = resumeData;
            id obj = [NSPropertyListSerialization propertyListWithData:resumeData options:0 format:0 error:nil];
            if ([obj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *resumeDict = obj;
                NSLog(@"%@", resumeDict);
                yctask.tmpName = [resumeDict valueForKey:@"NSURLSessionResumeInfoTempFileName"];
            }
           
        }else{
            [self downloadStatusChanged:YCDownloadStatusFailed task:yctask];
            [self startNextDownloadTask];
        }
    }
}



@end
