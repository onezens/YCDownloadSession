//
//  YCDownloadTask.m
//  YCDownloadSession-library
//
//  Created by wz on 2022/2/25.
//

#import "YCDownloadTask.h"

@interface YCDownloadTask()

@end

@implementation YCDownloadTask


+ (void)demo
{
    NSURLSession *session = NSURLSession.sharedSession;
    NSURLSessionConfiguration *conf = [NSURLSessionConfiguration new];
    NSURLSession *ss = [NSURLSession sessionWithConfiguration:conf];
    NSURLSessionDownloadTask *task = [ss downloadTaskWithURL:nil];
}

+ (instancetype)taskWithRequest:(NSURLRequest *)request
{
    return nil;
}
@end
