//
//  YCDownloadSessionConfig.m
//  YCDownloadSession-library
//
//  Created by wz on 2022/2/25.
//

#import "YCDownloadSessionConfig.h"

@implementation YCDownloadSessionConfig

- (instancetype)init
{
    if (self = [super init]) {
        self.identifier = @"bundle.id.YCDownloadSession";
        self.queue = [[NSOperationQueue alloc] init];
        self.queue.maxConcurrentOperationCount = 1;
    }
    return self;
}

@end
