
//
//  YCDownloadItem.m
//  YCDownloadSession
//
//  Created by wangzhen on 17/3/15.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "YCDownloadItem.h"
#import "YCDownloadSession.h"
#import <objc/runtime.h>

@implementation YCDownloadItem

- (void)setDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    _downloadTask = downloadTask;
    _downloadURL = [YCDownloadItem getURLFromTask:downloadTask];
}

- (void)updateItem {
    _response = _downloadTask.response;
    _fileSize = (NSInteger)[_response expectedContentLength];
    _suggestedFilename = [_response suggestedFilename];
}

- (NSString *)savePath {
    if (_savePath.length==0) {
        NSString *saveDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true).firstObject;
        saveDir = [saveDir stringByAppendingPathComponent:@"YCDownload/video"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:saveDir]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:saveDir withIntermediateDirectories:true attributes:nil error:nil];
        }
        saveDir =  [saveDir stringByAppendingPathComponent:self.suggestedFilename];
        return saveDir;
    }
    return _savePath;
}

+ (NSString *)getURLFromTask:(NSURLSessionTask *)task {
    NSURLRequest *req = [task currentRequest];
    return req.URL.absoluteString;
}

///  解档
- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super init]) {
        
        unsigned int count = 0;
        
        Ivar *ivars = class_copyIvarList([self class], &count);
        
        for (NSInteger i=0; i<count; i++) {
            
            Ivar ivar = ivars[i];
            NSString *name = [[NSString alloc] initWithUTF8String:ivar_getName(ivar)];
            if ([name isEqualToString:@"_downloadTask"]) continue;
            id value = [coder decodeObjectForKey:name];
            if(value) [self setValue:value forKey:name];
        }
        
        free(ivars);
    }
    return self;
}

///  归档
- (void)encodeWithCoder:(NSCoder *)coder
{
    
    unsigned int count = 0;
    
    Ivar *ivars = class_copyIvarList([self class], &count);
    
    for (NSInteger i=0; i<count; i++) {
        
        Ivar ivar = ivars[i];
        NSString *name = [[NSString alloc] initWithUTF8String:ivar_getName(ivar)];
        if ([name isEqualToString:@"_downloadTask"]) continue;
        id value = [self valueForKey:name];
        if(value) [coder encodeObject:value forKey:name];
    }
    
    free(ivars);
}


@end
