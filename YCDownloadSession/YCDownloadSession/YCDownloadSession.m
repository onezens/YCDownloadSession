////
////  YCDownloadSession.m
////  YCDownloadSession
////
////  Created by wz on 17/3/14.
////  Copyright © 2017年 onezen.cc. All rights reserved.
////  Contact me: http://www.onezen.cc
////  Github:     https://github.com/onezens/YCDownloadSession
////
//
//#import "YCDownloadSession.h"
//#import "YCDownloadDB.h"
//
//typedef void(^BGRecreateSessionBlock)(void);
//static NSString * const kIsAllowCellar = @"kIsAllowCellar";
//NSString * const kDownloadAllTaskFinishedNoti = @"kAllDownloadTaskFinishedNoti";
//NSString * const kDownloadUserIdentifyChanged = @"kDownloadUserIdentifyChanged";
//
//@interface YCDownloadSession ()<NSURLSessionDownloadDelegate>
//{
//    BGRecreateSessionBlock _bgRCSBlock;
//}
///**后台下载回调的handlers，所有的下载任务全部结束后调用*/
//@property (nonatomic, copy) BGCompletedHandler completedHandler;
//@property (nonatomic, strong, readonly) NSURLSession *session;
///**重新创建sessio标记位*/
//@property (nonatomic, assign) BOOL isNeedCreateSession;
//@property (nonatomic, strong) NSTimer *timer;
//
//@end
//
//@implementation YCDownloadSession
//
//static YCDownloadSession *_instance;
//
//+ (instancetype)downloadSession {
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        _instance = [[self alloc] init];
//    });
//    return _instance;
//}
//
//- (instancetype)init {
//    if (self = [super init]) {
//        NSLog(@"[YCDownloadSession init]");
//        _session = [self getDownloadURLSession];
//        _maxTaskCount = 1;
//        _downloadVersion = @"1.3.0";
//        NSMutableDictionary *dictM = [self.session valueForKey:@"tasks"];
//        [dictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSURLSessionDownloadTask *obj, BOOL * _Nonnull stop) {
//            YCDownloadTask *task = [[YCDownloadDB sharedDB] taskWithUrl:[YCDownloadTask getURLFromTask:obj]];
//            if(!task){
//                NSLog(@"[Error] not found task for url: %@", [YCDownloadTask getURLFromTask:obj]);
//                [obj cancel];
//            }else{
//                task.downloadTask = obj;
//            }
//        }];
//
//        [self addNotification];
////        if (dictM.count>0) {
////            //app重启，或者闪退的任务全部暂停,Xcode连接重启app
////            [self pauseAllDownloadTask];
////            NSLog(@"app start default pause all bg runing task! task count: %zd", dictM.count);
////            //waiting async pause task callback
////            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
////                [self detectAllCacheFileSize];
////            });
////        }
//
//    }
//    return self;
//}
//
//
//- (void)addNotification {
//
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
//
//}
//
//- (NSURLSession *)getDownloadURLSession {
//
//    NSURLSession *session = nil;
////    NSString *identifier = [self backgroundSessionIdentifier];
////    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];
////    sessionConfig.allowsCellularAccess = [[NSUserDefaults standardUserDefaults] boolForKey:kIsAllowCellar];
////    session = [NSURLSession sessionWithConfiguration:sessionConfig
////                                            delegate:self
////                                       delegateQueue:[NSOperationQueue mainQueue]];
//    return session;
//}
//
//- (NSString *)backgroundSessionIdentifier {
//    NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
//    NSString *identifier = [NSString stringWithFormat:@"%@.BackgroundSession", bundleId];
//    return identifier;
//}
//
//- (void)recreateSession {
//
//    _session = [self getDownloadURLSession];
//    //恢复正在下载的task状态
//    [[[YCDownloadDB sharedDB] fetchAllDownloadTasks] enumerateObjectsUsingBlock:^(YCDownloadTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
//        task.downloadTask = nil;
//        if (task.needToRestart) {
//            task.needToRestart = false;
//            [self resumeDownloadTask:task];
//        }
//    }];
//    NSLog(@"recreate Session success");
//}
//
//- (void)prepareRecreateSession {
//    [[[YCDownloadDB sharedDB] fetchAllDownloadTasks] enumerateObjectsUsingBlock:^(YCDownloadTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
//        if (task.downloadTask.state == NSURLSessionTaskStateRunning) {
//            task.needToRestart = true;
//            task.noNeedToStartNext = true;
//            [self pauseDownloadTask:task];
//        }
//    }];
//    [_session invalidateAndCancel];
//    self.isNeedCreateSession = true;
//}
//
//
//-(void)setMaxTaskCount:(NSInteger)maxTaskCount {
//    if (maxTaskCount>3) {
//        _maxTaskCount = 3;
//    }else if(maxTaskCount <= 0){
//        _maxTaskCount = 1;
//    }else{
//        _maxTaskCount = maxTaskCount;
//    }
//}
//
//- (NSInteger)currentTaskCount {
//    NSMutableDictionary *dictM = [self.session valueForKey:@"tasks"];
//    __block NSInteger count = 0;
//    [dictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
//        NSURLSessionTask *task = obj;
//        if (task.state == NSURLSessionTaskStateRunning) {
//            count++;
//        }
//    }];
//    return count;
//}
//
//- (void)appWillBecomeActive {
//    [self stopTimer];
//}
//
//- (void)appWillResignActive {
//    [[YCDownloadDB sharedDB] save];
//    [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadStatusChangedNoti object:nil];
//}
//
//- (void)appWillTerminate {
//    [[YCDownloadDB sharedDB] save];
//    [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadStatusChangedNoti object:nil];
//}
//
//#pragma mark - public
//
//- (YCDownloadTask *)startDownloadWithUrl:(NSString *)downloadURLString fileId:(NSString *)fileId delegate:(id<YCDownloadTaskDelegate>)delegate priority:(float)priority {
//    YCDownloadTask *task = [self startDownloadWithUrl:downloadURLString fileId:fileId delegate:delegate];
//    task.priority = priority;
//    return task;
//}
//
//- (YCDownloadTask *)startDownloadWithUrl:(NSString *)downloadURLString fileId:(NSString *)fileId delegate:(id<YCDownloadTaskDelegate>)delegate{
//    if (downloadURLString.length == 0)  return nil;
//
//    //判断是否是下载完成的任务
//    YCDownloadTask *task = [[YCDownloadDB sharedDB] taskWithUrl:downloadURLString];
//    if ([self detectDownloadTaskIsFinished:task]) {
//        task.delegate = delegate;
//        [self downloadStatusChanged:YCDownloadStatusFinished task:task];
//        return task;
//    }
//    if (!task) {
//        //判断任务的个数，如果达到最大值则返回，回调等待
//        if([self currentTaskCount] >= self.maxTaskCount){
//            //创建任务，让其处于等待状态
//            task = [self createDownloadTaskItemWithUrl:downloadURLString fileId:fileId delegate:delegate];
//            [self downloadStatusChanged:YCDownloadStatusWaiting task:task];
//            return task;
//        }else {
//            //开始下载
//            return [self startNewTaskWithUrl:downloadURLString fileId:fileId delegate:delegate];
//        }
//    }else{
//        task.delegate = delegate;
//        [self resumeDownloadTask:task];
//        return task;
//    }
//}
//
//- (void)stopDownloadTask:(YCDownloadTask *)task{
//    if (task && [[NSFileManager defaultManager] fileExistsAtPath:task.savePath]) {
//        [[NSFileManager defaultManager] removeItemAtPath:task.savePath error:nil];
//    }
//    [task.downloadTask cancel];
//    [[YCDownloadDB sharedDB] removeTask:task];
//    [self startNextDownloadTask];
//
//}
//
//- (void)pauseDownloadWithTaskId:(NSString *)taskId {
//    YCDownloadTask *task = [[YCDownloadDB sharedDB] taskWithTid:taskId];
//    [self pauseDownloadTask:task];
//}
//
//- (void)resumeDownloadWithTaskId:(NSString *)taskId {
//    YCDownloadTask *task = [[YCDownloadDB sharedDB] taskWithTid:taskId];
//    [self resumeDownloadTask:task];
//}
//
//- (void)stopDownloadWithTaskId:(NSString *)taskId {
//    YCDownloadTask *task = [[YCDownloadDB sharedDB] taskWithTid:taskId];
//    [self stopDownloadTask:task];
//}
//
//
//- (void)pauseAllDownloadTask{
//    [[[YCDownloadDB sharedDB] fetchAllDownloadTasks] enumerateObjectsUsingBlock:^(YCDownloadTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
//        if(task.downloadStatus == YCDownloadStatusDownloading && task.downloadTask.state != NSURLSessionTaskStateCompleted){
//            task.noNeedToStartNext = true;
//            [self pauseDownloadTask:task];
//        }else if (task.downloadStatus == YCDownloadStatusWaiting){
//            [self downloadStatusChanged:YCDownloadStatusPaused task:task];
//        }
//    }];
//}
//
//- (void)resumeAllDownloadTask {
//    NSLog(@"[YCDownloadSession resumeAllDownloadTask] no implement!");
//}
//
//- (void)removeAllCache {
//    [self pauseAllDownloadTask];
//    [[YCDownloadDB sharedDB].fetchAllDownloadTasks enumerateObjectsUsingBlock:^(YCDownloadTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
//        if ([[NSFileManager defaultManager] fileExistsAtPath:task.savePath]) {
//            [[NSFileManager defaultManager] removeItemAtPath:task.savePath error:nil];
//        }
//    }];
//    [[YCDownloadDB sharedDB] removeAllTasks];
//}
//
//- (YCDownloadTask *)taskForTaskId:(NSString *)taskId {
//    YCDownloadTask *task = [[YCDownloadDB sharedDB] taskWithTid:taskId];
//    return task;
//}
//
//- (void)allowsCellularAccess:(BOOL)isAllow {
//
//    [[NSUserDefaults standardUserDefaults] setBool:isAllow forKey:kIsAllowCellar];
//    [[NSUserDefaults standardUserDefaults] synchronize];
//    [self prepareRecreateSession];
//}
//
//- (BOOL)isAllowsCellularAccess {
//
//    return [[NSUserDefaults standardUserDefaults] boolForKey:kIsAllowCellar];
//}
//
//-(void)addCompletionHandler:(BGCompletedHandler)handler identifier:(NSString *)identifier{
//    if ([[self backgroundSessionIdentifier] isEqualToString:identifier]) {
//        self.completedHandler = handler;
//        //fix a crash in backgroud. for:  reason: backgroundDownload owner pid:252 preventSuspend  preventThrottleDownUI  preventIdleSleep  preventSuspendOnSleep
//        [self startTimer];
//
//    }
//}
//
//#pragma mark - private
//
//- (NSURLSessionDownloadTask *)downloadTaskWithUrl:(NSString *)url {
//    NSURL *downloadURL = [NSURL URLWithString:url];
//    NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
//    return [self.session downloadTaskWithRequest:request];
//}
//
//- (YCDownloadTask *)startNewTaskWithUrl:(NSString *)downloadURLString fileId:(NSString *)fileId delegate:(id<YCDownloadTaskDelegate>)delegate{
//
//    NSURLSessionDownloadTask *downloadTask = [self downloadTaskWithUrl:downloadURLString];
//    YCDownloadTask *task = [self createDownloadTaskItemWithUrl:downloadURLString fileId:fileId delegate:delegate];
//    task.downloadTask = downloadTask;
//    [downloadTask resume];
//    [self downloadStatusChanged:YCDownloadStatusDownloading task:task];
//    return task;
//}
//
//- (YCDownloadTask *)createDownloadTaskItemWithUrl:(NSString *)downloadURLString fileId:(NSString *)fileId delegate:(id<YCDownloadTaskDelegate>)delegate{
//    YCDownloadTask *task = [YCDownloadTask taskWithUrl:downloadURLString fileId:fileId delegate:delegate];
//    task.delegate = delegate;
//    [self downloadStatusChanged:YCDownloadStatusWaiting task:task];
//    [[YCDownloadDB sharedDB] save];
//    return task;
//}
//
//- (void)pauseDownloadTask:(YCDownloadTask *)task{
//    //暂停逻辑在这里处理 - (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
//    if (task.downloadTask) {
//        [task.downloadTask cancelByProducingResumeData:^(NSData * resumeData) { }];
//    } else {
//        task.downloadStatus = YCDownloadStatusPaused;
//        [self downloadStatusChanged:YCDownloadStatusPaused task:task];
//    }
//
//    if(!task.isSupportRange){
//        NSLog(@"Error: resource not support resume, because reponse headers not have the filed of 'Accept-Ranges' and 'ETag' !");
//
//    }
//}
//
//- (void)resumeDownloadTask:(YCDownloadTask *)task {
//
//    if(!task) return;
//
//    if ([self detectDownloadTaskIsFinished:task]) {
//        [self downloadStatusChanged:YCDownloadStatusFinished task:task];
//        return;
//    }
//
//    if (([self currentTaskCount] >= self.maxTaskCount) && task.downloadStatus != YCDownloadStatusDownloading) {
//        [self downloadStatusChanged:YCDownloadStatusWaiting task:task];
//        return;
//    }
//
//    NSData *data = task.resumeData;
//    if (data.length > 0) {
//        if(task.downloadTask && task.downloadTask.state == NSURLSessionTaskStateRunning){
//            [self downloadStatusChanged:YCDownloadStatusDownloading task:task];
//            return;
//        }
//        NSURLSessionDownloadTask *downloadTask = nil;
//        @try {
//            downloadTask = [YCResumeData downloadTaskWithCorrectResumeData:data urlSession:self.session];
//        } @catch (NSException *exception) {
//            [self downloadStatusChanged:YCDownloadStatusFailed task:task];
//            return;
//        }
//        task.downloadTask = downloadTask;
//        [downloadTask resume];
//        task.resumeData = nil;
//        [self downloadStatusChanged:YCDownloadStatusDownloading task:task];
//
//    }else{
//
//        if (!task.downloadTask || task.downloadTask.state == NSURLSessionTaskStateCompleted || task.downloadTask.state == NSURLSessionTaskStateCanceling) {
//            [task.downloadTask cancel];
//            NSURLSessionDownloadTask *downloadTask = [self downloadTaskWithUrl:task.downloadURL];
//            task.downloadTask = downloadTask;
//            [downloadTask resume];
//        }
//        [task.downloadTask resume];
//        [self downloadStatusChanged:YCDownloadStatusDownloading task:task];
//    }
//}
//
//- (void)startNextDownloadTask {
//    if ([self currentTaskCount] < self.maxTaskCount) {
//        [[YCDownloadDB sharedDB].fetchAllDownloadTasks enumerateObjectsUsingBlock:^(YCDownloadTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
//            if ((!task.downloadTask || task.downloadTask.state != NSURLSessionTaskStateRunning) && task.downloadStatus == YCDownloadStatusWaiting) {
//                [self resumeDownloadTask:task];
//            }
//        }];
//    }
//}
//
//- (void)downloadStatusChanged:(YCDownloadStatus)status task:(YCDownloadTask *)task{
//
//    task.downloadStatus = status;
//    switch (status) {
//        case YCDownloadStatusWaiting:
//            break;
//        case YCDownloadStatusDownloading:
//            break;
//        case YCDownloadStatusPaused:
//            break;
//        case YCDownloadStatusFailed:
//            break;
//        case YCDownloadStatusFinished:
//            [self startNextDownloadTask];
//            task.downloadedSize = task.fileSize;
//            break;
//        default:
//            break;
//    }
//
//    if ([task.delegate respondsToSelector:@selector(downloadStatusChanged:downloadTask:)]) {
//        [task.delegate downloadStatusChanged:status downloadTask:task];
//    }
//
//    [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadStatusChangedNoti object:nil];
//
//    //等task delegate方法执行完成后去判断该逻辑
//    //URLSessionDidFinishEventsForBackgroundURLSession 方法在后台执行一次，所以在此判断执行completedHandler
//    if (status == YCDownloadStatusFinished) {
//
//        if ([self allTaskFinised]) {
//            [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadAllTaskFinishedNoti object:nil];
//            //所有的任务执行结束之后调用completedHanlder
//            [self callBgCompletedHandler];
//        }
//    }
//}
//
//- (BOOL)allTaskFinised {
//
//    NSArray <YCDownloadTask *> *tasks = [[YCDownloadDB sharedDB] fetchAllDownloadTasks];
//    if (tasks.count == 0) return true;
//    __block BOOL isFinished = true;
//    [tasks enumerateObjectsUsingBlock:^(YCDownloadTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
//        if (task.downloadStatus == YCDownloadStatusWaiting || task.downloadStatus == YCDownloadStatusDownloading) {
//            isFinished = false;
//            *stop = true;
//        }
//    }];
//    return isFinished;
//}
//
//- (void)detectAllCacheFileSize{
//
//    NSArray <YCDownloadTask *> *tasks = [[YCDownloadDB sharedDB] fetchAllDownloadTasks];
//    [tasks enumerateObjectsUsingBlock:^(YCDownloadTask * _Nonnull task, NSUInteger idx, BOOL * _Nonnull stop) {
//        if(task.downloadStatus == YCDownloadStatusPaused || task.downloadStatus == YCDownloadStatusFailed){
//            //如果存在取最后一个，基本只有1个
//            NSArray *temps = [self getTmpPathsWithTask:task];
//            if(temps.count>0){
//                NSString *tmpPath = temps.lastObject;
//                task.downloadedSize = [self fileSizeWithPath:tmpPath];
//            }
//        }
//    }];
//    [[YCDownloadDB sharedDB] save];
//}
//
//- (NSInteger)fileSizeWithPath:(NSString *)path {
//    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) return 0;
//    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
//    return dic ? (NSInteger)[dic fileSize] : 0;
//}
//
//- (BOOL)detectDownloadTaskIsFinished:(YCDownloadTask *)task {
//
//    if (!task) return false;
//    if(task.downloadFinished) return true;
//    NSArray *tmpPaths = [self getTmpPathsWithTask:task];
//
//    __block BOOL isFinished = false;
//    [tmpPaths enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
//        NSString *path = obj;
//        NSInteger fileSize = [self fileSizeWithPath:path];
//        if (fileSize>0 && fileSize == task.fileSize) {
//            [[NSFileManager defaultManager] moveItemAtPath:path toPath:task.savePath error:nil];
//            isFinished = true;
//            task.downloadStatus = YCDownloadStatusFinished;
//            *stop = true;
//        }
//    }];
//
//    return isFinished;
//}
//
//- (NSArray *)getTmpPathsWithTask:(YCDownloadTask *)task {
//
//    if(!task) return nil;
//    NSMutableArray *tmpPaths = [NSMutableArray array];
//    NSFileManager *fileMgr = [NSFileManager defaultManager];
//    //download finish callback -> locationString
//    if (task.tempPath.length > 0 && [fileMgr fileExistsAtPath:task.tempPath]) {
//        [tmpPaths addObject:task.tempPath];
//    }else{
//        task.tempPath = nil;
//    }
//    if (task.tmpName.length > 0) {
//        NSString *downloadPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true).firstObject;
//        NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
//        //1. 系统正在下载的文件tmp文件存储路径和部分异常的tmp文件(回调失败)
//        downloadPath = [downloadPath stringByAppendingPathComponent: [NSString stringWithFormat:@"/com.apple.nsurlsessiond/Downloads/%@/", bundleId]];
//        downloadPath = [downloadPath stringByAppendingPathComponent:task.tmpName];
//        if([fileMgr fileExistsAtPath:downloadPath]) [tmpPaths addObject:downloadPath];
//
//        //2. 暂停下载后，系统从 downloadPath 目录移动到此
//        NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:task.tmpName];
//        if([fileMgr fileExistsAtPath:tmpPath]) [tmpPaths addObject:tmpPath];
//    }
//    if(tmpPaths.count == 0) task.tmpName = nil;
//    return tmpPaths;
//
//}
//
//#pragma mark - hander
//
//- (void)startTimer {
//    if (!self.timer) {
//        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerRun) userInfo:nil repeats:true];
//    }
//}
//- (void)stopTimer {
//    [self.timer invalidate];
//    self.timer = nil;
//}
//
//- (void)timerRun {
//    NSLog(@"background time remain: %f", [UIApplication sharedApplication].backgroundTimeRemaining);
//    //TODO: optimeze the logic for background session
//    if ([UIApplication sharedApplication].backgroundTimeRemaining < 15 && !_bgRCSBlock) {
//        NSLog(@"background time will up, need to call completed hander!");
//        __weak typeof(self) weakSelf = self;
//        _bgRCSBlock = ^{
//            [weakSelf callBgCompletedHandler];
//            [weakSelf stopTimer];
//        };
//        [self prepareRecreateSession];
//    }
//}
//
//- (void)callBgCompletedHandler {
//    if (self.completedHandler) {
//        self.completedHandler();
//        self.completedHandler = nil;
//    }
//}
//
//
//#pragma mark -  NSURLSessionDelegate
//
//- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
//
//    if (self.isNeedCreateSession) {
//        self.isNeedCreateSession = false;
//        [self recreateSession];
//        if (_bgRCSBlock) {
//            _bgRCSBlock();
//            _bgRCSBlock = nil;
//        }
//    }
//}
//- (void)URLSession:(NSURLSession *)session
//      downloadTask:(NSURLSessionDownloadTask *)downloadTask
//didFinishDownloadingToURL:(NSURL *)location {
//
//    NSLog(@"%s", __func__);
//
//    NSString *locationString = [location path];
//    NSError *error;
//
//    NSString *downloadUrl = [YCDownloadTask getURLFromTask:downloadTask];
//    YCDownloadTask *task = [[YCDownloadDB sharedDB] taskWithUrl:downloadUrl];
//    if(!task){
//        NSLog(@"[Download Finished] item nil error! url: %@", downloadUrl);
//        return;
//    }
//    task.tempPath = locationString;
//    NSInteger fileSize = [self fileSizeWithPath:locationString];
//    //校验文件大小
//    if (task.fileSize == 0) {
//        task.downloadTask = downloadTask;
//        [task updateTask];
//    }
//    BOOL isCompltedFile = (fileSize>0) && (fileSize == task.fileSize);
//    //文件大小不对，回调失败
//    if (!isCompltedFile) {
//        [self downloadStatusChanged:YCDownloadStatusFailed task:task];
//        //删除异常的缓存文件
//        [[NSFileManager defaultManager] removeItemAtPath:locationString error:nil];
//        return;
//    }
//    task.downloadedSize = task.fileSize;
//    task.downloadTask = nil;
//    [[NSFileManager defaultManager] moveItemAtPath:locationString toPath:task.savePath error:&error];
//    [self downloadStatusChanged:YCDownloadStatusFinished task:task];
//}
//
//- (void)URLSession:(NSURLSession *)session
//      downloadTask:(NSURLSessionDownloadTask *)downloadTask
//      didWriteData:(int64_t)bytesWritten
// totalBytesWritten:(int64_t)totalBytesWritten
//totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
//
//    YCDownloadTask *task = [[YCDownloadDB sharedDB] taskWithUrl:[YCDownloadTask getURLFromTask:downloadTask]];
//    task.downloadedSize = (NSInteger)totalBytesWritten;
//    if (task.fileSize == 0)  {
//        [task updateTask];
//        if ([task.delegate respondsToSelector:@selector(downloadCreated:)]) {
//            [task.delegate downloadCreated:task];
//        }
//    }
//
//    if([task.delegate respondsToSelector:@selector(downloadProgress:downloadedSize:fileSize:)]){
//        [task.delegate downloadProgress:task downloadedSize:task.downloadedSize fileSize:task.fileSize];
//    }
//
//    if (task.enableSpeed) {
//        dispatch_async(dispatch_get_global_queue(0, 0), ^{
//            [task downloadedSize:task.downloadedSize fileSize:task.fileSize];
//        });
//    }
//
//}
//
//- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
//willPerformHTTPRedirection:(NSHTTPURLResponse *)response
//        newRequest:(NSURLRequest *)request
// completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
//
//    //NSLog(@"willPerformHTTPRedirection ------> %@",response);
//}
//
//- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
//
//    YCDownloadTask *yctask =  [[YCDownloadDB sharedDB] taskWithUrl:[YCDownloadTask getURLFromTask:task]];
//    if (error) {
//
//        // check whether resume data are available
//        NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
//        if (resumeData) {
//            if (YC_DEVICE_VERSION >= 11.0f && YC_DEVICE_VERSION < 11.2f) {
//                //修正iOS11 多次暂停继续 文件大小不对的问题
//                resumeData = [YCResumeData cleanResumeData:resumeData];
//            }
//            //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
//            yctask.resumeData = resumeData;
//            id resumeDataObj = [NSPropertyListSerialization propertyListWithData:resumeData options:0 format:0 error:nil];
//            if ([resumeDataObj isKindOfClass:[NSDictionary class]]) {
//                NSDictionary *resumeDict = resumeDataObj;
//                yctask.tmpName = [resumeDict valueForKey:@"NSURLSessionResumeInfoTempFileName"];
//            }
//            yctask.resumeData = resumeData;
//            yctask.downloadTask = nil;
//            [self downloadStatusChanged:YCDownloadStatusPaused task:yctask];
//
//        }else{
//            NSLog(@"[didCompleteWithError] : %@",error);
//            [self downloadStatusChanged:YCDownloadStatusFailed task:yctask];
//        }
//    }
//    //需要下载下一个任务则下载下一个，否则还原noNeedToStartNext标识
//    !yctask.noNeedToStartNext ? [self startNextDownloadTask] :  (yctask.noNeedToStartNext = false);
//
//}
//
//@end
