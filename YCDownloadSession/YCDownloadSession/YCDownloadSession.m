//
//  YCDownloadSession.m
//  YCDownloadSession
//
//  Created by wz on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Contact me: http://www.onezen.cc
//  Github:     https://github.com/onezens/YCDownloadSession
//

#import "YCDownloadSession.h"

static NSString * const kIsAllowCellar = @"kIsAllowCellar";
typedef void(^BGRecreateSessionBlock)(void);

@interface YCDownloadSession ()<NSURLSessionDownloadDelegate>

/**正在下载的task*/
@property (nonatomic, strong) NSMutableDictionary *downloadTasks;
/**后台下载回调的handlers，所有的下载任务全部结束后调用*/
@property (nonatomic, copy) BGCompletedHandler completedHandler;
@property (nonatomic, strong, readonly) NSURLSession *session;
/**重新创建sessio标记位*/
@property (nonatomic, assign) BOOL isNeedCreateSession;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, copy) BGRecreateSessionBlock bgRCSBlock;

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
        NSLog(@"YCDownloadSession init");
        //初始化
        _session = [self getDownloadURLSession];
        _maxTaskCount = 1;
        _downloadVersion = @"1.2.1";
        
        //获取保存在本地的数据是否为空，为空则初始化
        _downloadTasks = [NSKeyedUnarchiver unarchiveObjectWithFile:[self getArchiverPath]];
        if(!_downloadTasks) _downloadTasks = [NSMutableDictionary dictionary];
        
        [self compatiableDownloadData];
        [self addNotification];
        
        //获取背景session正在运行的(app重启，或者闪退会有任务)
        NSMutableDictionary *dictM = [self.session valueForKey:@"tasks"];
        [dictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            YCDownloadTask *task = [self getDownloadTaskWithUrl:[YCDownloadTask getURLFromTask:obj]];
            if(!task){
                [obj cancel];
            }else{
                task.downloadTask = obj;
            }
        }];
        
//        if (dictM.count>0) {
//            //app重启，或者闪退的任务全部暂停,Xcode连接重启app
//            [self pauseAllDownloadTask];
//            NSLog(@"app start default pause all bg runing task! task count: %zd", dictM.count);
//            //waiting async pause task callback
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//                [self detectAllCacheFileSize];
//            });
//        }

    }
    return self;
}


- (void)addNotification {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    
}

- (void)compatiableDownloadData {
    //TODO: compatible version 1.0.0
    NSString *downloadingDataPath = [self getArchiverPathIsDownloaded:false];
    NSString *downloadedDataPath = [self getArchiverPathIsDownloaded:true];
    NSMutableDictionary *downloadingDictM = [NSKeyedUnarchiver unarchiveObjectWithFile:downloadingDataPath];
    NSMutableDictionary *downloadedDictM = [NSKeyedUnarchiver unarchiveObjectWithFile:downloadedDataPath];
    
    [downloadingDictM enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, YCDownloadTask *  _Nonnull obj, BOOL * _Nonnull stop) {
        [self.downloadTasks setValue:obj forKey:[YCDownloadTask taskIdForUrl:key fileId:nil]];
    }];
    
    [downloadedDictM enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, YCDownloadTask *   _Nonnull obj, BOOL * _Nonnull stop) {
        [self.downloadTasks setValue:obj forKey:[YCDownloadTask taskIdForUrl:key fileId:nil]];
    }];
    
    [[NSFileManager defaultManager] removeItemAtPath:downloadingDataPath error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:downloadedDataPath error:nil];
    [self saveDownloadStatus];
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
    
    _session = [self getDownloadURLSession];
    //恢复正在下载的task状态
    [self.downloadTasks enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        YCDownloadTask *task = obj;
        task.downloadTask = nil;
        if (task.needToRestart) {
            task.needToRestart = false;
            [self resumeDownloadTask:task];
        }
    }];
    NSLog(@"recreate Session success");
}

- (void)prepareRecreateSession {
    [self.downloadTasks enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        YCDownloadTask *task = obj;
        if (task.downloadTask.state == NSURLSessionTaskStateRunning) {
            task.needToRestart = true;
            task.noNeedToStartNext = true;
            [self pauseDownloadTask:task];
        }
    }];
    
    [_session invalidateAndCancel];
    self.isNeedCreateSession = true;
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
    NSMutableDictionary *dictM = [self.session valueForKey:@"tasks"];
    __block NSInteger count = 0;
    [dictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSURLSessionTask *task = obj;
        if (task.state == NSURLSessionTaskStateRunning) {
            count++;
        }
    }];
    return count;
}

- (void)appWillBecomeActive {
    [self stopTimer];
}

- (void)appWillResignActive {
    [self saveDownloadStatus];
    [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadStatusChangedNoti object:nil];
    NSLog(@"%s", __func__);
}

- (void)appWillTerminate {
    [self saveDownloadStatus];
    [[NSNotificationCenter defaultCenter] postNotificationName:kDownloadStatusChangedNoti object:nil];
    NSLog(@"%s", __func__);
}


#pragma mark - public

- (YCDownloadTask *)startDownloadWithUrl:(NSString *)downloadURLString fileId:(NSString *)fileId delegate:(id<YCDownloadTaskDelegate>)delegate priority:(float)priority {
    YCDownloadTask *task = [self startDownloadWithUrl:downloadURLString fileId:fileId delegate:delegate];
    task.priority = priority;
    return task;
}

- (YCDownloadTask *)startDownloadWithUrl:(NSString *)downloadURLString fileId:(NSString *)fileId delegate:(id<YCDownloadTaskDelegate>)delegate{
    if (downloadURLString.length == 0)  return nil;
    
    //判断是否是下载完成的任务
    YCDownloadTask *task = [self.downloadTasks valueForKey:[YCDownloadTask taskIdForUrl:downloadURLString fileId:fileId]];
    if ([self detectDownloadTaskIsFinished:task]) {
        task.delegate = delegate;
        [self downloadStatusChanged:YCDownloadStatusFinished task:task];
        return task;
    }
    if (!task) {
        //判断任务的个数，如果达到最大值则返回，回调等待
        if([self currentTaskCount] >= self.maxTaskCount){
            //创建任务，让其处于等待状态
            task = [self createDownloadTaskItemWithUrl:downloadURLString fileId:fileId delegate:delegate];
            [self downloadStatusChanged:YCDownloadStatusWaiting task:task];
            return task;
        }else {
            //开始下载
            return [self startNewTaskWithUrl:downloadURLString fileId:fileId delegate:delegate];
        }
    }else{
        task.delegate = delegate;
        [self resumeDownloadTask:task];
        return task;
    }
}


- (void)pauseDownloadWithTask:(YCDownloadTask *)task {
    [self pauseDownloadTask:task];
}

- (void)resumeDownloadWithTask:(YCDownloadTask *)task{
    [self resumeDownloadTask:task];
}

- (void)stopDownloadWithTask:(YCDownloadTask *)task{
    [self stopDownloadWithTaskId:task.taskId];
}

- (void)pauseDownloadWithTaskId:(NSString *)taskId {
    YCDownloadTask *task = [self.downloadTasks valueForKey:taskId];
    //TODO: compatiable 1.0.0
    if(!task){
        task = [self compatibleOldTaskId:taskId];
    }
    //TODO: compatiable 1.0.0 end
    [self pauseDownloadTask:task];
}

- (void)resumeDownloadWithTaskId:(NSString *)taskId{
    YCDownloadTask *task = [self.downloadTasks valueForKey:taskId];
    //TODO: compatiable 1.0.0
    if(!task){
        task = [self compatibleOldTaskId:taskId];
    }
    //TODO: compatiable 1.0.0 end
    [self resumeDownloadTask:task];
}

- (void)stopDownloadWithTaskId:(NSString *)taskId {
    
    YCDownloadTask *task = [self.downloadTasks valueForKey:taskId];
    //TODO: compatiable 1.0.0
    if(!task){
        task = [self compatibleOldTaskId:taskId];
    }
    //TODO: compatiable 1.0.0 end
    if (task && [[NSFileManager defaultManager] fileExistsAtPath:task.savePath]) {
        [[NSFileManager defaultManager] removeItemAtPath:task.savePath error:nil];
    }
    [task.downloadTask cancel];
    if(task.taskId.length>0)[self.downloadTasks removeObjectForKey:task.taskId];
    [self saveDownloadStatus];
    [self startNextDownloadTask];
}


- (void)pauseAllDownloadTask{

    [self.downloadTasks enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, YCDownloadTask * _Nonnull obj, BOOL * _Nonnull stop) {
        NSLog(@"downloadTask:%@ state: %zd  - %zd", obj.downloadTask, obj.downloadTask.state, obj.downloadStatus);
        if(obj.downloadStatus == YCDownloadStatusDownloading && obj.downloadTask.state != NSURLSessionTaskStateCompleted){
            obj.noNeedToStartNext = true;
            [self pauseDownloadTask:obj];
        }else if (obj.downloadStatus == YCDownloadStatusWaiting){
            [self downloadStatusChanged:YCDownloadStatusPaused task:obj];
        }
    }];

}

- (void)resumeAllDownloadTask {
    
}

- (void)removeAllCache {
    [self pauseAllDownloadTask];
    [self.downloadTasks enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, YCDownloadTask *  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:obj.savePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:obj.savePath error:nil];
        }
    }];
    [self.downloadTasks removeAllObjects];
    [self saveDownloadStatus];
    
}

- (YCDownloadTask *)taskForTaskId:(NSString *)taskId {
    YCDownloadTask *task = [self.downloadTasks valueForKey:taskId];
    //TODO: compatiable 1.0.0
    if(!task){
        task = [self compatibleOldTaskId:taskId];
    }
    
    return task;
}

- (void)allowsCellularAccess:(BOOL)isAllow {
    
    [[NSUserDefaults standardUserDefaults] setBool:isAllow forKey:kIsAllowCellar];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self prepareRecreateSession];
}

- (BOOL)isAllowsCellularAccess {
    
    return [[NSUserDefaults standardUserDefaults] boolForKey:kIsAllowCellar];
}

-(void)addCompletionHandler:(BGCompletedHandler)handler identifier:(NSString *)identifier{
    if ([[self backgroundSessionIdentifier] isEqualToString:identifier]) {
        self.completedHandler = handler;
        //fix a crash in backgroud. for:  reason: backgroundDownload owner pid:252 preventSuspend  preventThrottleDownUI  preventIdleSleep  preventSuspendOnSleep
        [self startTimer];
        
    }
}
#pragma mark - private

- (YCDownloadTask *)startNewTaskWithUrl:(NSString *)downloadURLString fileId:(NSString *)fileId delegate:(id<YCDownloadTaskDelegate>)delegate{
    
    NSURL *downloadURL = [NSURL URLWithString:downloadURLString];
    NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
    NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithRequest:request];
    YCDownloadTask *task = [self createDownloadTaskItemWithUrl:downloadURLString fileId:fileId delegate:delegate];
    task.downloadTask = downloadTask;
    [downloadTask resume];
    [self downloadStatusChanged:YCDownloadStatusDownloading task:task];
    return task;
}

- (YCDownloadTask *)createDownloadTaskItemWithUrl:(NSString *)downloadURLString fileId:(NSString *)fileId delegate:(id<YCDownloadTaskDelegate>)delegate{
    
    YCDownloadTask *task = [YCDownloadTask taskWithUrl:downloadURLString fileId:fileId delegate:delegate];
    task.delegate = delegate;
    [self.downloadTasks setObject:task forKey:task.taskId];
    [self downloadStatusChanged:YCDownloadStatusWaiting task:task];
    return task;
}

- (void)pauseDownloadTask:(YCDownloadTask *)task{
    //暂停逻辑在这里处理 - (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
    if (task.downloadTask) {
        [task.downloadTask cancelByProducingResumeData:^(NSData * resumeData) { }];
    } else {
        task.downloadStatus = YCDownloadStatusPaused;
    }
    if(!task.isSupportRange){
        NSLog(@"Error: resource not support resume, because reponse headers not have the filed of 'Accept-Ranges' and 'ETag' !");
    }
}

- (void)resumeDownloadTask:(YCDownloadTask *)task {
    
    if(!task) return;
    
    if ([self detectDownloadTaskIsFinished:task]) {
        [self downloadStatusChanged:YCDownloadStatusFinished task:task];
        return;
    }
    
    if (([self currentTaskCount] >= self.maxTaskCount) && task.downloadStatus != YCDownloadStatusDownloading) {
        [self downloadStatusChanged:YCDownloadStatusWaiting task:task];
        return;
    }
    
    NSData *data = task.resumeData;
    if (data.length > 0) {
        if(task.downloadTask && task.downloadTask.state == NSURLSessionTaskStateRunning){
            [self downloadStatusChanged:YCDownloadStatusDownloading task:task];
            return;
        }
        NSURLSessionDownloadTask *downloadTask = nil;
        @try {
            downloadTask = [YCResumeData downloadTaskWithCorrectResumeData:data urlSession:self.session];
        } @catch (NSException *exception) {
            [self downloadStatusChanged:YCDownloadStatusFailed task:task];
            return;
        }
        task.downloadTask = downloadTask;
        [downloadTask resume];
        task.resumeData = nil;
        [self downloadStatusChanged:YCDownloadStatusDownloading task:task];
        
    }else{
        
        if (!task.downloadTask || task.downloadTask.state == NSURLSessionTaskStateCompleted || task.downloadTask.state == NSURLSessionTaskStateCanceling) {
            [task.downloadTask cancel];
            NSURL *downloadURL = [NSURL URLWithString:task.downloadURL];
            NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
            NSURLSessionDownloadTask *downloadTask = [self.session downloadTaskWithRequest:request];
            task.downloadTask = downloadTask;
        }
        [task.downloadTask resume];
        [self downloadStatusChanged:YCDownloadStatusDownloading task:task];
    }
}

- (void)startNextDownloadTask {
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
            [self callBgCompletedHandler];
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


- (void)saveDownloadStatus {
    
    [NSKeyedArchiver archiveRootObject:self.downloadTasks toFile:[self getArchiverPath]];
}

//TODO: compatible old version 1.0.0
- (NSString *)getArchiverPathIsDownloaded:(BOOL)isDownloaded {
    NSString *saveDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true).firstObject;
    saveDir = [saveDir stringByAppendingPathComponent:@"YCDownload"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:saveDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:saveDir withIntermediateDirectories:true attributes:nil error:nil];
    }
    saveDir = isDownloaded ? [saveDir stringByAppendingPathComponent:@"YCDownloaded.data"] : [saveDir stringByAppendingPathComponent:@"YCDownloading.data"];
    return saveDir;
}

-(YCDownloadTask *)compatibleOldTaskId:(NSString *)taskId {
    
    __block YCDownloadTask *oldTask = nil;
    [self.downloadTasks enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, YCDownloadTask *  _Nonnull obj, BOOL * _Nonnull stop) {
        if([obj.downloadURL isEqualToString:taskId]){
            oldTask = obj;
            *stop = true;
        }
    }];
    return oldTask;
}


- (NSString *)getArchiverPath{
    NSString *saveDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true).firstObject;
    saveDir = [saveDir stringByAppendingPathComponent:@"YCDownload"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:saveDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:saveDir withIntermediateDirectories:true attributes:nil error:nil];
    }
    saveDir = [saveDir stringByAppendingPathComponent:@"YCDownload.db"];
    return saveDir;
}

- (void)detectAllCacheFileSize{
    
    [self.downloadTasks enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, YCDownloadTask *  _Nonnull task, BOOL * _Nonnull stop) {
        if(task.downloadStatus == YCDownloadStatusPaused || task.downloadStatus == YCDownloadStatusFailed){
            //如果存在取最后一个，基本只有1个
            NSArray *temps = [self getTmpPathsWithTask:task];
            if(temps.count>0){
                NSString *tmpPath = temps.lastObject;
                task.downloadedSize = [self fileSizeWithPath:tmpPath];
            }
        }
    }];
    [self saveDownloadStatus];
}

- (NSInteger)fileSizeWithPath:(NSString *)path {
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) return 0;
    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return dic ? (NSInteger)[dic fileSize] : 0;
}

- (BOOL)detectDownloadTaskIsFinished:(YCDownloadTask *)task {
    
    if (!task) return false;
    if(task.downloadFinished) return true;
    NSArray *tmpPaths = [self getTmpPathsWithTask:task];

    __block BOOL isFinished = false;
    [tmpPaths enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *path = obj;
        NSInteger fileSize = [self fileSizeWithPath:path];
        if (fileSize>0 && fileSize == task.fileSize) {
            [[NSFileManager defaultManager] moveItemAtPath:path toPath:task.savePath error:nil];
            isFinished = true;
            task.downloadStatus = YCDownloadStatusFinished;
            *stop = true;
        }
    }];
    
    return isFinished;
}

- (NSArray *)getTmpPathsWithTask:(YCDownloadTask *)task {
    
    if(!task) return nil;
    NSMutableArray *tmpPaths = [NSMutableArray array];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    //download finish callback -> locationString
    if (task.tempPath.length > 0 && [fileMgr fileExistsAtPath:task.tempPath]) {
        [tmpPaths addObject:task.tempPath];
    }else{
        task.tempPath = nil;
    }
    if (task.tmpName.length > 0) {
        NSString *downloadPath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true).firstObject;
        NSString *bundleId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
        //1. 系统正在下载的文件tmp文件存储路径和部分异常的tmp文件(回调失败)
        downloadPath = [downloadPath stringByAppendingPathComponent: [NSString stringWithFormat:@"/com.apple.nsurlsessiond/Downloads/%@/", bundleId]];
        downloadPath = [downloadPath stringByAppendingPathComponent:task.tmpName];
        if([fileMgr fileExistsAtPath:downloadPath]) [tmpPaths addObject:downloadPath];
        
        //2. 暂停下载后，系统从 downloadPath 目录移动到此
        NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:task.tmpName];
        if([fileMgr fileExistsAtPath:tmpPath]) [tmpPaths addObject:tmpPath];
    }
    if(tmpPaths.count == 0) task.tmpName = nil;
    return tmpPaths;
    
}


- (YCDownloadTask *)getDownloadTaskWithUrl:(NSString *)downloadUrl{
    
    NSMutableDictionary *tasks = self.downloadTasks ;
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


#pragma mark - hander

- (void)startTimer {
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerRun) userInfo:nil repeats:true];
    }
}
- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)timerRun {
    NSLog(@"background time remain: %f", [UIApplication sharedApplication].backgroundTimeRemaining);
    //TODO: optimeze the logic for background session
    if ([UIApplication sharedApplication].backgroundTimeRemaining < 15 && !self.bgRCSBlock) {
        NSLog(@"background time will up, need to call completed hander!");
        __weak typeof(self) weakSelf = self;
        self.bgRCSBlock = ^{
            [weakSelf callBgCompletedHandler];
            [weakSelf stopTimer];
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

#pragma mark -  NSURLSessionDelegate

//将一个后台session作废完成后的回调，用来切换是否允许使用蜂窝煤网络，重新创建session
- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(nullable NSError *)error {
    
    if (self.isNeedCreateSession) {
        self.isNeedCreateSession = false;
        [self recreateSession];
        if (self.bgRCSBlock) {
            self.bgRCSBlock();
            self.bgRCSBlock = nil;
        }
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
    YCDownloadTask *task = [self getDownloadTaskWithUrl:downloadUrl];
    if(!task){
        NSLog(@"download finished , item nil error!!!! url: %@", downloadUrl);
        return;
    }
    task.tempPath = locationString;
    NSInteger fileSize =[self fileSizeWithPath:locationString];
    //校验文件大小
    if (task.fileSize == 0) {
        task.downloadTask = downloadTask;
        [task updateTask];
    }
    //BOOL isCompltedFile = (fileSize>0) && ((fileSize == task.fileSize) || task.fileSize == 0);
    BOOL isCompltedFile = (fileSize>0) && (fileSize == task.fileSize);
    //文件大小不对，回调失败
    if (!isCompltedFile) {
        [self downloadStatusChanged:YCDownloadStatusFailed task:task];
        //删除异常的缓存文件
        [[NSFileManager defaultManager] removeItemAtPath:locationString error:nil];
        return;
    }
    task.downloadedSize = task.fileSize;
    task.downloadTask = nil;
    [[NSFileManager defaultManager] moveItemAtPath:locationString toPath:task.savePath error:&error];

    if (task.downloadURL.length != 0) {
        [self.downloadTasks setObject:task forKey:task.taskId];
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
    
    YCDownloadTask *task = [self getDownloadTaskWithUrl:[YCDownloadTask getURLFromTask:downloadTask]];
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
    
    if (task.enableSpeed) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [task downloadedSize:task.downloadedSize fileSize:task.fileSize];
        });
    }
    
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
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    YCDownloadTask *yctask = [self getDownloadTaskWithUrl:[YCDownloadTask getURLFromTask:task]];
    if (error) {
        
        // check whether resume data are available
        NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
        if (resumeData) {
            
            float deviceVersion = [[[UIDevice currentDevice] systemVersion] floatValue];
            if (deviceVersion >= 11.0f && deviceVersion < 11.2f) {
                //修正iOS11 多次暂停继续 文件大小不对的问题
                resumeData = [YCResumeData cleanResumeData:resumeData];
            }
            //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
            yctask.resumeData = resumeData;
            id resumeDataObj = [NSPropertyListSerialization propertyListWithData:resumeData options:0 format:0 error:nil];
            if ([resumeDataObj isKindOfClass:[NSDictionary class]]) {
                NSDictionary *resumeDict = resumeDataObj;
                yctask.tmpName = [resumeDict valueForKey:@"NSURLSessionResumeInfoTempFileName"];
            }
            yctask.resumeData = resumeData;
            yctask.downloadTask = nil;
            [self saveDownloadStatus];
            [self downloadStatusChanged:YCDownloadStatusPaused task:yctask];
           
        }else{
            if (yctask.fileSize == 0) {
                [self downloadStatusChanged:YCDownloadStatusPaused task:yctask];
            } else {
                [self downloadStatusChanged:YCDownloadStatusFailed task:yctask];
            }
        }
    }
    //需要下载下一个任务则下载下一个，否则还原noNeedToStartNext标识
    !yctask.noNeedToStartNext ? [self startNextDownloadTask] :  (yctask.noNeedToStartNext = false);
    
}



@end
