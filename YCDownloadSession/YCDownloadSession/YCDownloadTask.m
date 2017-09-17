//
//  YCDownloadTask.m
//  YCDownloadSession
//
//  Created by wz on 17/3/15.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "YCDownloadTask.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>

@implementation YCDownloadTask


#pragma mark - public

- (void)updateTask {
    
    _fileSize = (NSInteger)[_downloadTask.response expectedContentLength];
    [[NSNotificationCenter defaultCenter] postNotificationName:kYCDownloadSessionSaveDownloadStatus object:nil];
}

#pragma mark - getter

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
    NSURLRequest *req = [task currentRequest];
    return req.URL.absoluteString;
}



#pragma mark - setter

- (void)setDownloadURL:(NSString *)downloadURL {
    
    _downloadURL = downloadURL;
    NSString *fileName = [self cachedFileNameForKey:downloadURL isHavePathExtension:true];
    _saveName = fileName;
}

- (void)setDownloadTask:(NSURLSessionDownloadTask *)downloadTask {
    if (_downloadTask && downloadTask && ![_downloadTask isEqual:downloadTask]) { //防止重复下载
        [_downloadTask suspend];
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


/**
 通过md5加密生成->保存文件名
 */
- (NSString *)cachedFileNameForKey:(NSString *)key isHavePathExtension:(BOOL)isHave {
    const char *str = [key UTF8String];
    if (str == NULL) {
        str = "";
    }
    unsigned char r[CC_MD5_DIGEST_LENGTH];
    CC_MD5(str, (CC_LONG)strlen(str), r);
    NSString *filename = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                          r[0], r[1], r[2], r[3], r[4], r[5], r[6], r[7], r[8], r[9], r[10], r[11], r[12], r[13], r[14], r[15]];
    
    return isHave ? [filename stringByAppendingPathExtension:key.pathExtension] : filename;
}




@end
