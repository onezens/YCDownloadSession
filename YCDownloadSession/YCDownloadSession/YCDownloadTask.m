//
//  YCDownloadTask.m
//  YCDownloadSession
//
//  Created by wz on 17/3/15.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Contact me: http://www.onezen.cc
//  Github:     https://github.com/onezens/YCDownloadSession
//

#import "YCDownloadTask.h"
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>
#import "YCDownloadSession.h"

@interface YCDownloadTask()
{
    NSString *_saveName;
}
@end

@implementation YCDownloadTask

- (instancetype)initWithUrl:(NSString *)url fileId:(NSString *)fileId delegate:(id<YCDownloadTaskDelegate>)delegate {
    
    if(self = [super init]){
        _downloadURL = url;
        _fileId = fileId;
        _delegate = delegate;
        _compatibleKey = [YCDownloadSession downloadSession].downloadVersion;
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
    
- (BOOL)isSupportRange {
    if([self.downloadTask.response isKindOfClass:[NSHTTPURLResponse class]]){
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)self.downloadTask.response;
        NSString *rangeHeader = [response.allHeaderFields valueForKey:@"Accept-Ranges"];
        NSString *etag = [response.allHeaderFields valueForKey:@"ETag"];
        return rangeHeader.length>0 && etag.length>0;
    }
    return true;
}

-(NSString *)taskId {
    return [YCDownloadTask taskIdForUrl:self.downloadURL fileId:self.fileId];
}

- (NSString *)savePath {
    return [YCDownloadTask savePathWithSaveName:self.saveName];
}

-(BOOL)downloadFinished {
    
    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:self.savePath error:nil];
    NSInteger fileSize = dic ? (NSInteger)[dic fileSize] : 0;
    return [[NSFileManager defaultManager] fileExistsAtPath:self.savePath] && (fileSize == self.fileSize);
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

- (void)setSaveName:(NSString *)saveName {
    _saveName = saveName;
    [YCDownloadSession.downloadSession saveDownloadStatus];
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


#pragma mark -- YCResumeData implementation

static NSString * const kNSURLSessionDownloadURL = @"NSURLSessionDownloadURL";
static NSString * const kNSURLSessionResumeInfoTempFileName = @"NSURLSessionResumeInfoTempFileName";
static NSString * const kNSURLSessionResumeBytesReceived = @"NSURLSessionResumeBytesReceived";
static NSString * const kNSURLSessionResumeCurrentRequest = @"NSURLSessionResumeCurrentRequest";
static NSString * const kNSURLSessionResumeOriginalRequest = @"NSURLSessionResumeOriginalRequest";
static NSString * const kNSURLSessionResumeEntityTag = @"NSURLSessionResumeEntityTag";
static NSString * const kNSURLSessionResumeByteRange = @"NSURLSessionResumeByteRange";
static NSString * const kNSURLSessionResumeInfoVersion = @"NSURLSessionResumeInfoVersion";
static NSString * const kNSURLSessionResumeServerDownloadDate = @"NSURLSessionResumeServerDownloadDate";


@interface YCResumeData()

@end

@implementation YCResumeData

- (instancetype)initWithResumeData:(NSData *)resumeData {
    if (self = [super init]) {
        [self decodeResumeData:resumeData];
    }
    return self;
}


- (void)decodeResumeData:(NSData *)resumeData {
    
    id resumeDataObj = [NSPropertyListSerialization propertyListWithData:resumeData options:0 format:0 error:nil];
    if ([resumeDataObj isKindOfClass:[NSDictionary class]]) {
        NSDictionary *resumeDict = resumeDataObj;
        NSString *downloadUrl = [resumeDict valueForKey:kNSURLSessionDownloadURL];
        NSString *tempName = [resumeDict valueForKey:kNSURLSessionResumeInfoTempFileName];
        NSNumber *downloadSize = [resumeDict valueForKey:kNSURLSessionResumeBytesReceived];
        NSData *currentReqData = [resumeDict valueForKey:kNSURLSessionResumeCurrentRequest];
        NSData *originalReqData = [resumeDict valueForKey:kNSURLSessionResumeOriginalRequest];
        NSString *resumeTag = [resumeDict valueForKey:kNSURLSessionResumeEntityTag];
        NSString *resumeRange = [resumeDict valueForKey:kNSURLSessionResumeByteRange];
        NSNumber *resumeInfoVersion = [resumeDict valueForKey:kNSURLSessionResumeInfoVersion];
        NSString *downloadDate = [resumeDict valueForKey:kNSURLSessionResumeServerDownloadDate];
        
        
        _downloadUrl = downloadUrl;
        _tempName = tempName;
        _downloadSize = downloadSize.integerValue;
        _resumeTag = resumeTag;
        _resumeRange = resumeRange;
        _resumeInfoVersion = resumeInfoVersion.integerValue;
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        _downloadDate = [formatter dateFromString:downloadDate];
        
        id obj = [NSKeyedUnarchiver unarchiveObjectWithData:currentReqData];
        id obj2= [NSKeyedUnarchiver unarchiveObjectWithData:originalReqData];
//        id obj3 = [NSPropertyListSerialization propertyListWithData:currentReqData options:0 format:0 error:nil];
        NSLog(@"%@", [obj class]);
        NSLog(@"%@", [obj2 class]);
        NSLog(@"--------->resumeRange:  %@", resumeRange);
    }
}


+ (NSData *)correctRequestData:(NSData *)data
{
    if (!data) {
        return nil;
    }
    // return the same data if it's correct
    if ([NSKeyedUnarchiver unarchiveObjectWithData:data] != nil) {
        return data;
    }
    NSMutableDictionary *archive = [[NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:nil error:nil] mutableCopy];
    
    if (!archive) {
        return nil;
    }
    NSInteger k = 0;
    id objectss = archive[@"$objects"];
    while ([objectss[1] objectForKey:[NSString stringWithFormat:@"$%ld",(long)k]] != nil) {
        k += 1;
    }
    NSInteger i = 0;
    while ([archive[@"$objects"][1] objectForKey:[NSString stringWithFormat:@"__nsurlrequest_proto_prop_obj_%ld",(long)i]] != nil) {
        NSMutableArray *arr = archive[@"$objects"];
        NSMutableDictionary *dic = arr[1];
        id obj = [dic objectForKey:[NSString stringWithFormat:@"__nsurlrequest_proto_prop_obj_%ld",(long)i]];
        if (obj) {
            [dic setValue:obj forKey:[NSString stringWithFormat:@"$%zd",i+k]];
            [dic removeObjectForKey:[NSString stringWithFormat:@"__nsurlrequest_proto_prop_obj_%ld",(long)i]];
            [arr replaceObjectAtIndex:1 withObject:dic];
            archive[@"$objects"] = arr;
        }
        i++;
    }
    if ([archive[@"$objects"][1] objectForKey:@"__nsurlrequest_proto_props"] != nil) {
        NSMutableArray *arr = archive[@"$objects"];
        NSMutableDictionary *dic = arr[1];
        id obj = [dic objectForKey:@"__nsurlrequest_proto_props"];
        if (obj) {
            [dic setValue:obj forKey:[NSString stringWithFormat:@"$%zd",i+k]];
            [dic removeObjectForKey:@"__nsurlrequest_proto_props"];
            [arr replaceObjectAtIndex:1 withObject:dic];
            archive[@"$objects"] = arr;
        }
    }
    // Rectify weird "NSKeyedArchiveRootObjectKey" top key to NSKeyedArchiveRootObjectKey = "root"
    if ([archive[@"$top"] objectForKey:@"NSKeyedArchiveRootObjectKey"] != nil) {
        [archive[@"$top"] setObject:archive[@"$top"][@"NSKeyedArchiveRootObjectKey"] forKey: NSKeyedArchiveRootObjectKey];
        [archive[@"$top"] removeObjectForKey:@"NSKeyedArchiveRootObjectKey"];
    }
    // Reencode archived object
    NSData *result = [NSPropertyListSerialization dataWithPropertyList:archive format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    return result;
}
+ (NSMutableDictionary *)getResumeDictionary:(NSData *)data
{
    NSMutableDictionary *iresumeDictionary = nil;
    if (IS_IOS10ORLATER) {
        id root = nil;
        id  keyedUnarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        @try {
            root = [keyedUnarchiver decodeTopLevelObjectForKey:@"NSKeyedArchiveRootObjectKey" error:nil];
            if (root == nil) {
                root = [keyedUnarchiver decodeTopLevelObjectForKey:NSKeyedArchiveRootObjectKey error:nil];
            }
        } @catch(NSException *exception) {
            
        }
        [keyedUnarchiver finishDecoding];
        iresumeDictionary = [root mutableCopy];
    }
    
    if (iresumeDictionary == nil) {
        iresumeDictionary = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListMutableContainersAndLeaves format:nil error:nil];
    }
    return iresumeDictionary;
}

+ (NSData *)correctResumeData:(NSData *)data
{
    NSString *kResumeCurrentRequest = kNSURLSessionResumeCurrentRequest;
    NSString *kResumeOriginalRequest = kNSURLSessionResumeOriginalRequest;
    if (data == nil) {
        return  nil;
    }
    NSMutableDictionary *resumeDictionary = [YCResumeData getResumeDictionary:data];
    if (resumeDictionary == nil) {
        return nil;
    }
    resumeDictionary[kResumeCurrentRequest] =  [YCResumeData correctRequestData: resumeDictionary[kResumeCurrentRequest]];
    resumeDictionary[kResumeOriginalRequest] = [YCResumeData correctRequestData:resumeDictionary[kResumeOriginalRequest]];
    NSData *result = [NSPropertyListSerialization dataWithPropertyList:resumeDictionary format:NSPropertyListXMLFormat_v1_0 options:0 error:nil];
    return result;
}


+ (NSURLSessionDownloadTask *)downloadTaskWithCorrectResumeData:(NSData *)resumeData urlSession:(NSURLSession *)urlSession {
    NSString *kResumeCurrentRequest = kNSURLSessionResumeCurrentRequest;
    NSString *kResumeOriginalRequest = kNSURLSessionResumeOriginalRequest;
    
    NSData *cData = [YCResumeData correctResumeData:resumeData];
    cData = cData ? cData:resumeData;
    NSURLSessionDownloadTask *task = [urlSession downloadTaskWithResumeData:cData];
    NSMutableDictionary *resumeDic = [YCResumeData getResumeDictionary:cData];
    if (resumeDic) {
        if (task.originalRequest == nil) {
            NSData *originalReqData = resumeDic[kResumeOriginalRequest];
            NSURLRequest *originalRequest = [NSKeyedUnarchiver unarchiveObjectWithData:originalReqData ];
            if (originalRequest) {
                [task setValue:originalRequest forKey:@"originalRequest"];
            }
        }
        if (task.currentRequest == nil) {
            NSData *currentReqData = resumeDic[kResumeCurrentRequest];
            NSURLRequest *currentRequest = [NSKeyedUnarchiver unarchiveObjectWithData:currentReqData];
            if (currentRequest) {
                [task setValue:currentRequest forKey:@"currentRequest"];
            }
        }
    }
    return task;
}

+ (NSData *)cleanResumeData:(NSData *)resumeData {
    NSString *dataString = [[NSString alloc] initWithData:resumeData encoding:NSUTF8StringEncoding];
    if ([dataString containsString:@"<key>NSURLSessionResumeByteRange</key>"]) {
        NSRange rangeKey = [dataString rangeOfString:@"<key>NSURLSessionResumeByteRange</key>"];
        NSString *headStr = [dataString substringToIndex:rangeKey.location];
        NSString *backStr = [dataString substringFromIndex:rangeKey.location];
        
        NSRange rangeValue = [backStr rangeOfString:@"</string>\n\t"];
        NSString *tailStr = [backStr substringFromIndex:rangeValue.location + rangeValue.length];
        dataString = [headStr stringByAppendingString:tailStr];
    }
    return [dataString dataUsingEncoding:NSUTF8StringEncoding];
}

@end
