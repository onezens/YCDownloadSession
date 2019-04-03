//
//  YCDownloader.m
//  YCDownloadSession
//
//  Created by wz on 2018/8/27.
//  Copyright © 2018 onezen.cc. All rights reserved.
//  Contact me: http://www.onezen.cc/about/
//  Github:     https://github.com/onezens/YCDownloadSession
//

#import "YCDownloader.h"
#import "YCDownloadUtils.h"
#import "YCDownloadTask.h"
#import "YCDownloadDB.h"

typedef void(^BGRecreateSessionBlock)(void);
static NSString * const kIsAllowCellar = @"kIsAllowCellar";

@interface YCDownloadTask(Downloader)
@property (nonatomic, assign) NSInteger pid;
@property (nonatomic, assign) NSInteger stid;
@property (nonatomic, assign) BOOL isDeleted;
@property (nonatomic, copy) NSString *tmpName;
@property (nonatomic, assign) BOOL needToRestart;
@property (nonatomic, strong) NSURLRequest *request;
@property (nonatomic, assign, readonly) BOOL isFinished;
@property (nonatomic, assign, readonly) BOOL isSupportRange;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@end

@interface YCDownloader()<NSURLSessionDelegate>
{
    BGRecreateSessionBlock _bgRCSBlock;
    dispatch_source_t _timerSource;
}
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, assign) BOOL isNeedCreateSession;
@property (nonatomic, strong) NSMutableDictionary <NSURLSessionDownloadTask *, YCDownloadTask *> *memCache;
@property (nonatomic, copy) BGCompletedHandler completedHandler;
@property (nonatomic, strong) NSMutableArray <YCDownloadTask *> *bgRCSTasks;
@end

@implementation YCDownloader

#pragma mark - init

+ (instancetype)downloader {
    static dispatch_once_t onceToken;
    static YCDownloader *_downloader;
    dispatch_once(&onceToken, ^{
        _downloader = [[self alloc] initWithPrivate];
    });
    return _downloader;
}

- (instancetype)initWithPrivate {
    if (self = [super init]) {
        NSLog(@"[YCDownloader init]");
        _session = [self backgroundUrlSession];
        _memCache = [NSMutableDictionary dictionary];
        _bgRCSTasks = [NSMutableArray array];
        [self recoveryExceptionTasks];
        [self addNotification];
    }
    return self;
}


- (instancetype)init {
    NSAssert(false, @"use +[YCDownloader downloader] instead!");
    return nil;
}
- (NSString *)backgroundSessionIdentifier {
    NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    NSString *identifier = [NSString stringWithFormat:@"%@.BGS.YCDownloader", bundleId];
    return identifier;
}

- (NSURLSession *)backgroundUrlSession {
    NSURLSession *session = nil;
    NSString *identifier = [self backgroundSessionIdentifier];
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
    sessionConfig.allowsCellularAccess = [[NSUserDefaults standardUserDefaults] boolForKey:kIsAllowCellar];
    session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    return session;
}

- (NSInteger)sessionTaskIdWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    return downloadTask.taskIdentifier;
}

- (void)recoveryExceptionTasks {
    NSMutableDictionary *dictM = [self.session valueForKey:@"tasks"];
    [dictM.copy enumerateKeysAndObjectsUsingBlock:^(NSNumber *_Nonnull key, NSURLSessionDownloadTask *obj, BOOL * _Nonnull stop) {
        YCDownloadTask *task = [YCDownloadDB taskWithStid:key.integerValue].firstObject;
        task ? [self memCacheDownloadTask:obj task:task] : [obj cancel];
        if (task.downloadTask && task.downloadTask.state != NSURLSessionTaskStateRunning) {
            [self pauseTask:task];
        }
    }];
}
- (void)addNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillBecomActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
}

#pragma mark - event

- (void)appWillBecomActive {
    [self endTimer];
    if (self.completedHandler) self.completedHandler();
    self.completedHandler = nil;
    _bgRCSBlock = nil;
}

- (void)appWillResignActive {
    [YCDownloadDB saveAllData];
}

#pragma mark - download handler
- (NSURLRequest *)requestWithUrlStr:(NSString *)urlStr {
    NSURL *url = [NSURL URLWithString:urlStr];
    return [NSMutableURLRequest requestWithURL:url];;
}

- (YCDownloadTask *)downloadWithUrl:(NSString *)url progress:(YCProgressHandler)progress completion:(YCCompletionHandler)completion {
    NSURLRequest *request = [self requestWithUrlStr:url];
    return [self downloadWithRequest:request progress:progress completion:completion];
}

- (YCDownloadTask *)downloadWithRequest:(NSURLRequest *)request progress:(YCProgressHandler)progress completion:(YCCompletionHandler)completion{
    return [self downloadWithRequest:request progress:progress completion:completion priority:0];
}

- (YCDownloadTask *)downloadWithRequest:(NSURLRequest *)request progress:(YCProgressHandler)progress completion:(YCCompletionHandler)completion priority:(float)priority{
    YCDownloadTask *task = [YCDownloadTask taskWithRequest:request progress:progress completion:completion];
    [self saveDownloadTask:task];
    return task;
}

- (YCDownloadTask *)resumeDownloadTaskWithTid:(NSString *)tid progress:(YCProgressHandler)progress completion:(YCCompletionHandler)completion {
    YCDownloadTask *task = [YCDownloadDB taskWithTid:tid];
    task.completionHandler = completion;
    task.progressHandler = progress;
    [self resumeTask:task];
    return task;
}

- (BOOL)resumeTask:(YCDownloadTask *)task {
    if(!task) return false;
    if (self.isNeedCreateSession) {
        //fix crash: #25 #35 Attempted to create a task in a session that has been invalidated
        [self.bgRCSTasks addObject:task];
        return true;
    }
    if (!task.resumeData && task.downloadTask.state == NSURLSessionTaskStateSuspended){
        [task.downloadTask resume];
        NSError *err = nil;
        BOOL success = [self checkDownloadTaskState:task.downloadTask task:task error:&err];
        if(!success) NSLog(@"[resumeTask] task resume failed: %@", err);
        return success;
    }else if (task.downloadTask && self.memCache[task.downloadTask] && task.downloadTask.state == NSURLSessionTaskStateRunning) {
        return true;
    }else if (!task.resumeData && task.downloadTask){
        NSError *error = [NSError errorWithDomain:@"resume NSURLSessionDownloadTask error state" code:10004 userInfo:nil];
        [self completionDownloadTask:task localPath:nil error:error];
        NSLog(@"[resumeTask] task resume failed: %@", error);
        return false;
    }else if (!task.resumeData){
        if (!task.request) {
            NSURLRequest *request = [self requestWithUrlStr:task.downloadURL];
            task.request = request;
        }
        NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithRequest:task.request];
        [self memCacheDownloadTask:downloadTask task:task];
        task.downloadTask = downloadTask;
        [task.downloadTask resume];
        NSError *err = nil;
        BOOL success = [self checkDownloadTaskState:task.downloadTask task:task error:&err];
        if(!success) NSLog(@"[resumeTask] task resume failed: %@", err);
        return success;
    }
    
    NSURLSessionDownloadTask *downloadTask = nil;
    @try {
        downloadTask = [YCResumeData downloadTaskWithCorrectResumeData:task.resumeData urlSession:self.session];
    } @catch (NSException *exception) {
        NSError *error = [NSError errorWithDomain:exception.description code:10002 userInfo:exception.userInfo];
        [self completionDownloadTask:task localPath:nil error:error];
        NSLog(@"[resumeTask] task resume failed: %@", error);
        return false;
    }
    if (!downloadTask) {
        NSError *error = [NSError errorWithDomain:@"resume NSURLSessionDownloadTask nil!" code:10003 userInfo:nil];
        [self completionDownloadTask:task localPath:nil error:error];
        NSLog(@"[resumeTask] task resume failed: %@", error);
        return false;
    }
    [self memCacheDownloadTask:downloadTask task:task];
    [downloadTask resume];
    NSError *err = nil;
    if (![self checkDownloadTaskState:downloadTask task:task error:&err]) {
        NSLog(@"[resumeTask] task resume failed: %@", err);
        return false;
    }
    NSLog(@"[resumeTask] task resume success");
    task.resumeData = nil;
    return true;
}

- (BOOL)checkDownloadTaskState:(NSURLSessionDownloadTask *)downloadTask task:(YCDownloadTask *)task error:(NSError **)err {
    if (downloadTask && downloadTask.state != NSURLSessionTaskStateRunning) {
        NSError *error = [NSError errorWithDomain:[NSString stringWithFormat:@"task resume failed, downloadTask.state error : %ld", (long)downloadTask.state] code:10006 userInfo:nil];
        [self completionDownloadTask:task localPath:nil error:error];
        if(err) *err = error;
        return false;
    }
    return true;
}

- (void)pauseTask:(YCDownloadTask *)task{
    [task.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) { }];
}

- (void)cancelTask:(YCDownloadTask *)task{
    task.isDeleted = true;
    [task.downloadTask cancel];
}

#pragma mark - recreate session

- (void)prepareRecreateSession {
    if (self.isNeedCreateSession) return;
    self.isNeedCreateSession = true;
    [[YCDownloadDB fetchAllDownloadTasks] enumerateObjectsUsingBlock:^(YCDownloadTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
        if (task.downloadTask && task.downloadTask.state == NSURLSessionTaskStateRunning) {
            task.needToRestart = true;
            [self pauseTask:task];
        }
    }];
    [_session invalidateAndCancel];
}
- (void)recreateSession {
    
    _session = [self backgroundUrlSession];
    //恢复正在下载的task状态
    [[YCDownloadDB fetchAllDownloadTasks] enumerateObjectsUsingBlock:^(YCDownloadTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
        task.downloadTask = nil;
        if (task.needToRestart) {
            task.needToRestart = false;
            [self resumeTask:task];
        }
    }];
    NSLog(@"[recreateSession] recreate Session success");
}

#pragma mark - setter & getter

- (void)setAllowsCellularAccess:(BOOL)allowsCellularAccess {
    if ([self allowsCellularAccess] != allowsCellularAccess) {
        [[NSUserDefaults standardUserDefaults] setBool:allowsCellularAccess forKey:kIsAllowCellar];
        [self prepareRecreateSession];
    }
}

- (BOOL)allowsCellularAccess {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kIsAllowCellar];
}

#pragma mark - cache

- (void)memCacheDownloadTask:(NSURLSessionDownloadTask *)downloadTask  task:(YCDownloadTask *)task{
    task.downloadTask = downloadTask;
    //record taskId for coldLaunch recovery download
    task.stid = [self sessionTaskIdWithDownloadTask:downloadTask];
    [self.memCache setObject:task forKey:downloadTask];
    [self saveDownloadTask:task];
}

- (void)removeMembCacheTask:(NSURLSessionDownloadTask *)downloadTask task:(YCDownloadTask *)task {
    task.stid = -1;
    [self.memCache removeObjectForKey:downloadTask];
}

- (void)completionDownloadTask:(YCDownloadTask *)task localPath:(NSString *)localPath error:(NSError *)error {
    if(task.downloadTask) [self removeMembCacheTask:task.downloadTask task:task];
    task.completionHandler? task.completionHandler(localPath, error) : false;
    if (self.taskCachekMode == YCDownloadTaskCacheModeDefault && task.completionHandler) {
        [self removeDownloadTask:task];
    }else{
        task.stid = -1;
        [self saveDownloadTask:task];
    }
    task.downloadTask = nil;
}

- (void)removeDownloadTask:(YCDownloadTask *)task {
    [YCDownloadDB removeTask:task];
}

- (void)saveDownloadTask:(YCDownloadTask *)task {
    [YCDownloadDB saveTask:task];
}

- (YCDownloadTask *)taskWithSessionTask:(NSURLSessionDownloadTask *)downloadTask {
    NSAssert(downloadTask, @"taskWithSessionTask downloadTask can not nil!");
    if (!downloadTask)  return nil;
    __block YCDownloadTask *task = [self.memCache objectForKey:downloadTask];
    NSString *url = [YCDownloadUtils urlStrWithDownloadTask:downloadTask];
    if (!task) {
        NSArray <YCDownloadTask *>* tasks = [YCDownloadDB taskWithStid:[self sessionTaskIdWithDownloadTask:downloadTask]];
        [tasks enumerateObjectsUsingBlock:^(YCDownloadTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.downloadURL isEqualToString:url]) {
                task = obj;
                *stop = true;
            }
        }];
    }
    if (!task) {
        NSArray *tasks = [YCDownloadDB taskWithUrl:url];
        //fixme: optimize logic for multible tasks for same url
        [tasks enumerateObjectsUsingBlock:^(YCDownloadTask * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.downloadTask == nil && downloadTask.taskIdentifier == obj.stid) {
                task = obj;
                *stop = true;
            }
        }];
        if (!task) task = tasks.firstObject;
    }
    NSAssert(task, @"taskWithSessionTask task can not nil!");
    return task;
}

#pragma mark - Handler

- (void)startTimer {
    [self endTimer];
    dispatch_source_t timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    _timerSource = timerSource;
    double interval = 1 * NSEC_PER_SEC;
    dispatch_source_set_timer(timerSource, dispatch_time(DISPATCH_TIME_NOW, interval), interval, 0);
    __weak typeof(self) weakself = self;
    dispatch_source_set_event_handler(timerSource, ^{
        [weakself callTimer];
    });
    dispatch_resume(_timerSource);
}

- (void)endTimer {
    if(_timerSource) dispatch_source_cancel(_timerSource);
    _timerSource = nil;
}

- (void)callTimer {
    NSLog(@"[callTimer] background time remain: %f", [UIApplication sharedApplication].backgroundTimeRemaining);
    //TODO: optimeze the logic for background session
    if ([UIApplication sharedApplication].backgroundTimeRemaining < 15 && !_bgRCSBlock) {
        NSLog(@"[callTimer] background time will up, need to call completed hander!");
        __weak typeof(self) weakSelf = self;
        _bgRCSBlock = ^{
            [weakSelf endBGCompletedHandler];
        };
        [self prepareRecreateSession];
    }
}

- (void)callBgCompletedHandler {
    if (self.completedHandler) {
        self.completedHandler();
        self.completedHandler = nil;
    }
}

- (void)endBGCompletedHandler{
    
    if(!self.completedHandler) return;
    [self.bgRCSTasks.copy enumerateObjectsUsingBlock:^(YCDownloadTask *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self resumeTask:obj];
        NSLog(@"[session invalidated] fix pass!");
    }];
    [self.bgRCSTasks removeAllObjects];
    [self endTimer];
    [self callBgCompletedHandler];
}

-(void)addCompletionHandler:(BGCompletedHandler)handler identifier:(NSString *)identifier{
    if ([[self backgroundSessionIdentifier] isEqualToString:identifier]) {
        self.completedHandler = handler;
        //fix a crash in backgroud. for:  reason: backgroundDownload owner pid:252 preventSuspend  preventThrottleDownUI  preventIdleSleep  preventSuspendOnSleep
        [self startTimer];
    }
}

#pragma mark - NSURLSession delegate

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
    if (self.isNeedCreateSession) {
        self.isNeedCreateSession = false;
        [self recreateSession];
        if (_bgRCSBlock) {
            _bgRCSBlock();
            _bgRCSBlock = nil;
        }
    }
}

- (NSInteger)statusCodeWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    if ([downloadTask.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)downloadTask.response;
        return response.statusCode;
    }
    return -1;
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
    YCDownloadTask *task = [self taskWithSessionTask:downloadTask];

    NSInteger statusCode = [self statusCodeWithDownloadTask:downloadTask];
    if (!(statusCode == 200 || statusCode == 206)) {
        task.downloadedSize = 0;
        NSLog(@"[didFinishDownloadingToURL] http status code error: %ld", (long)statusCode);
        NSError *error = [NSError errorWithDomain:@"http status code error" code:11002 userInfo:nil];
        [self completionDownloadTask:task localPath:nil error:error];
        return;
    }
    
    NSString *localPath = [location path];
    if (task.fileSize==0) [task updateTask];
    int64_t fileSize = [YCDownloadUtils fileSizeWithPath:localPath];
    NSError *error = nil;
    if (fileSize>0 && fileSize != task.fileSize) {
        NSString *errStr = [NSString stringWithFormat:@"[YCDownloader didFinishDownloadingToURL] fileSize Error, task fileSize: %lld tmp fileSize: %lld", task.fileSize, fileSize];
        NSLog(@"%@",errStr);
        error = [NSError errorWithDomain:errStr code:11001 userInfo:nil];
        localPath = nil;
    }else{
        task.downloadedSize = fileSize;
    }
    [self completionDownloadTask:task localPath:localPath error:error];
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSInteger statusCode = [self statusCodeWithDownloadTask:downloadTask];
    if (!(statusCode == 200 || statusCode == 206)) {
        return;
    }
    YCDownloadTask *task = [self taskWithSessionTask:downloadTask];
    if (!task) {
        [downloadTask cancel];
        NSAssert(false,@"didWriteData task nil!");
    }
    task.downloadedSize = totalBytesWritten;
    if(task.fileSize==0) [task updateTask];
    task.progress.totalUnitCount = totalBytesExpectedToWrite>0 ? totalBytesExpectedToWrite : task.fileSize;
    task.progress.completedUnitCount = totalBytesWritten;
    if(task.progressHandler) task.progressHandler(task.progress, task);
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionDownloadTask *)downloadTask didCompleteWithError:(NSError *)error {
    if (!error) return;
    YCDownloadTask *task = [self taskWithSessionTask:downloadTask];
    if(task.isDeleted) return;
    // check whether resume data are available
    NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
    if (resumeData) {
        //can resume
        if (YC_DEVICE_VERSION >= 11.0f && YC_DEVICE_VERSION < 11.2f) {
            //修正iOS11 多次暂停继续 文件大小不对的问题
            resumeData = [YCResumeData cleanResumeData:resumeData];
        }
        //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
        task.resumeData = resumeData;
        id resumeDataObj = [NSPropertyListSerialization propertyListWithData:resumeData options:0 format:0 error:nil];
        if ([resumeDataObj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *resumeDict = resumeDataObj;
            task.tmpName = [resumeDict valueForKey:@"NSURLSessionResumeInfoTempFileName"];
        }
        task.resumeData = resumeData;
        [self saveDownloadTask:task];
        [self removeMembCacheTask:downloadTask task:task];
        task.downloadTask = nil;
    }else{
        //cannot resume
        NSLog(@"[didCompleteWithError] : %@",error);
        [self completionDownloadTask:task localPath:nil error:error];
    }
}

@end
