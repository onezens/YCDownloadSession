//
//  NSURLSessionDownloadTask+YCDownload.m
//  YCDownloadSession
//
//  Created by wz on 2024/2/22.
//

#import "NSURLSessionTask+YCDownload.h"
#import <objc/runtime.h>

typedef YCDownloadTask * (^yc_weakPointer)(void);
yc_weakPointer yc_setWeakPointer(YCDownloadTask *task) {
    __weak YCDownloadTask *weakRef = task;
    return ^{
        return weakRef;
    };
}

YCDownloadTask * yc_getWeakPointer(yc_weakPointer blk) {
    return blk ? blk() : nil;
}

@implementation NSURLSessionTask (YCDownload)

- (YCDownloadTask *)ycTask
{
    id obj = objc_getAssociatedObject(self, _cmd);
    return yc_getWeakPointer(obj);
}

- (void)setYcTask:(YCDownloadTask *)ycTask
{
    yc_weakPointer obj = yc_setWeakPointer(ycTask);
    objc_setAssociatedObject(self, @selector(ycTask), obj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
