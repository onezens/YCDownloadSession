//
//  YCDownloadSession.m
//  Pods-YCDownloadSession
//
//  Created by wz on 2022/2/25.
//

#import "YCDownloadSession.h"

@interface YCDownloadSession ()

@property (nonatomic, strong) YCDownloadSessionConfig *config;

@property (nonatomic, strong) NSURLSession *urlSession;

@end

@implementation YCDownloadSession


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
    NSURLSessionConfiguration *urlSessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"id"];
    session.urlSession = [NSURLSession sessionWithConfiguration:urlSessionConfig];
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
    NSURLSessionDownloadTask *dtask = [self.urlSession downloadTaskWithRequest:request];
    YCDownloadTask *task = [YCDownloadTask taskWithTask:dtask];
    return task;
}


@end
