//
//  YCDownloadTask.m
//  YCDownloadSession
//
//  Created by wz on 17/3/15.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Github: https://github.com/onezens/YCDownloadSession
//

#import "YCDownloadTask.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>
#import "YCDownloadSession.h"

@implementation YCDownloadTask

- (instancetype)initWithUrl:(NSString *)url fileId:(NSString *)fileId delegate:(id<YCDownloadTaskDelegate>)delegate {
    
    if(self = [super init]){
        _downloadURL = url;
        _fileId = fileId;
        _delegate = delegate;
    }
    return self;
}

+ (instancetype)taskWithUrl:(NSString *)url fileId:(NSString *)fileId delegate:(id<YCDownloadTaskDelegate>)delegate {
    return [[YCDownloadTask alloc] initWithUrl:url fileId:fileId delegate:delegate];
}

#pragma mark - public

- (void)updateTask {
    
    _fileSize = (NSInteger)[_downloadTask.response expectedContentLength];
}

- (void)resume {
    [YCDownloadSession.downloadSession resumeDownloadWithTask:self];
}

- (void)pause {
    [YCDownloadSession.downloadSession pauseDownloadWithTask:self];
}

- (void)remove {
    [YCDownloadSession.downloadSession stopDownloadWithTask:self];
}

#pragma mark - getter

-(NSString *)taskId {
    return [YCDownloadTask taskIdForUrl:self.downloadURL fileId:self.fileId];
}

- (NSString *)savePath {
    return [YCDownloadTask savePathWithSaveName:self.saveName];
}

-(BOOL)downloadFinished {
    return [[NSFileManager defaultManager] fileExistsAtPath:self.savePath];
}

- (NSString *)saveName {
    if (_saveName.length==0) {
        NSString *name = [YCDownloadTask taskIdForUrl:self.downloadURL fileId:self.fileId];
        NSString *pathExtension =  [YCDownloadTask getPathExtensionWithUrl:self.downloadURL];
        name = pathExtension.length>0 ? [name stringByAppendingPathExtension:pathExtension] : name;
        return name;
    }
    return _saveName;
}

+ (NSString *)taskIdForUrl:(NSString *)url fileId:(NSString *)fileId {
    NSString *name = [YCDownloadTask md5ForString:fileId.length>0 ? [NSString stringWithFormat:@"%@-%@",url, fileId] : url];
    return name;
}

+ (NSString *)savePathWithSaveName:(NSString *)saveName {
    
    NSString *saveDir = [self saveDir];
    saveDir =  [saveDir stringByAppendingPathComponent:saveName];
    return saveDir;

}

+ (NSString *)saveDir {
    NSString *saveDir = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, true).firstObject;
    saveDir = [saveDir stringByAppendingPathComponent:@"YCDownload/video"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:saveDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:saveDir withIntermediateDirectories:true attributes:nil error:nil];
    }
    return saveDir;
}


+ (NSString *)getURLFromTask:(NSURLSessionTask *)task {
    
    //301/302定向的originRequest和currentRequest的url不同
    NSString *url = nil;
    NSURLRequest *req = [task originalRequest];
    url = req.URL.absoluteString;
    //bridge swift , sometimes originalRequest not have url
    if(url.length==0){
        url = [task currentRequest].URL.absoluteString;
    }
    return url;
}


+ (NSString *)md5ForString:(NSString *)string {
    const char *str = [string UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *md5Result = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    return md5Result;
}

#pragma mark - setter

- (void)setDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    if (_downloadTask && downloadTask && ![_downloadTask isEqual:downloadTask]) { //防止重复下载
        [_downloadTask cancel];
    }
    _downloadTask = downloadTask;
}

#pragma mark - private

///  解档
- (instancetype)initWithCoder:(NSCoder *)coder
{
    if (self = [super init]) {
        
        unsigned int count = 0;
        
        Ivar *ivars = class_copyIvarList([self class], &count);
        
        for (NSInteger i=0; i<count; i++) {
            
            Ivar ivar = ivars[i];
            NSString *name = [[NSString alloc] initWithUTF8String:ivar_getName(ivar)];
            if ([name isEqualToString:@"_downloadTask"] || [name isEqualToString:@"_delegate"]) continue;
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
        if ([name isEqualToString:@"_downloadTask"] || [name isEqualToString:@"_delegate"]) continue;
        id value = [self valueForKey:name];
        if(value) [coder encodeObject:value forKey:name];
    }
    
    free(ivars);
}

+ (NSString *)getPathExtensionWithUrl:(NSString *)url {
    NSString *pathExtension = [url pathExtension];
    //过滤url中的参数，取出单独文件名
    NSRange range = [pathExtension rangeOfString:@"?"];
    if (range.location>0 && range.length == 1) {
        pathExtension = [pathExtension substringToIndex:range.location];
    }
    return pathExtension;
}

@end
