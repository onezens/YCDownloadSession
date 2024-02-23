//
//  YCDownloadTask.m
//  YCDownloadSession-library
//
//  Created by wz on 2022/2/25.
//

#import "YCDownloadTask.h"
#import "YCDownloadSession.h"
#import "NSURLSessionTask+YCDownload.h"

@interface YCDownloadTask()

@property (nonatomic, strong) NSURLSessionDownloadTask *dTask;

@property (nonatomic, weak) NSURLSession *session;

@property (nonatomic, assign, readwrite) YCDownloadTaskState state;

@end

@implementation YCDownloadTask

- (void)buildTaskWithSession:(NSURLSession *)session request:(NSURLRequest *)request
{
    self.state = YCDownloadTaskStatePending;
    self.session = session;
    self.dTask = [session downloadTaskWithRequest:request];
    self.dTask.ycTask = self;
}

- (void)pause
{
    self.state = YCDownloadTaskStateSuspended;
    [self.dTask cancel];
}

- (void)pauseWithResumeData:(void (^)(NSData * _Nullable))completionHandler
{
    self.state = YCDownloadTaskStateSuspended;
    [self.dTask cancelByProducingResumeData:completionHandler];
}

- (void)resume
{
    if (self.state == YCDownloadTaskStateRunning) {
        return;
    }
    self.state = YCDownloadTaskStateRunning;
    [self.dTask resume];
}

- (void)resumeWithResumeData:(NSData *)resumeData
{
    if (self.state == YCDownloadTaskStateRunning) {
        return;
    }
    if (!resumeData) {
        [self resume];
        return;
    }
    NSURLSessionDownloadTask *newTask = [self.session downloadTaskWithResumeData:resumeData];
    newTask.ycTask = self;
    self.dTask = newTask;
    [self resume];
}

- (void)resumeWithResumeData:(NSData *)resumeData completion:(YCDownloadCompletionBlock)completionBlock
{
    if (completionBlock) {
        self.completionBlock = completionBlock;
    }
    [self resumeWithResumeData:resumeData];
}

- (void)stop
{
    self.state = YCDownloadTaskStateSuspended;
    [self.dTask suspend];
}

@end
