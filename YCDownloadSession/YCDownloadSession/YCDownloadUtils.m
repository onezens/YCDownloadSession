//
//  YCDownloadUtils.m
//  YCDownloadSession
//
//  Created by wz on 2018/6/22.
//  Copyright © 2018年 onezen.cc. All rights reserved.
//

#import "YCDownloadUtils.h"
#import <CommonCrypto/CommonDigest.h>
#import <sqlite3.h>

#define kCommonUtilsGigabyte (1024 * 1024 * 1024)
#define kCommonUtilsMegabyte (1024 * 1024)
#define kCommonUtilsKilobyte 1024

@implementation YCDownloadUtils

+ (NSUInteger)fileSystemFreeSize {
    NSUInteger totalFreeSpace = 0;
    NSError *error = nil;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    
    if (dictionary) {
        NSNumber *freeFileSystemSizeInBytes = [dictionary objectForKey:NSFileSystemFreeSize];
        totalFreeSpace = [freeFileSystemSizeInBytes unsignedIntegerValue];
    }
    return totalFreeSpace;
}

+ (NSString *)fileSizeStringFromBytes:(NSUInteger)byteSize {
    if (kCommonUtilsGigabyte <= byteSize) {
        return [NSString stringWithFormat:@"%@GB", [self numberStringFromDouble:(double)byteSize / kCommonUtilsGigabyte]];
    }
    if (kCommonUtilsMegabyte <= byteSize) {
        return [NSString stringWithFormat:@"%@MB", [self numberStringFromDouble:(double)byteSize / kCommonUtilsMegabyte]];
    }
    if (kCommonUtilsKilobyte <= byteSize) {
        return [NSString stringWithFormat:@"%@KB", [self numberStringFromDouble:(double)byteSize / kCommonUtilsKilobyte]];
    }
    return [NSString stringWithFormat:@"%luB", (unsigned long)byteSize];
}

+ (NSString *)numberStringFromDouble:(const double)num {
    NSInteger section = round((num - (NSInteger)num) * 100);
    if (section % 10) {
        return [NSString stringWithFormat:@"%.2f", num];
    }
    if (section > 0) {
        return [NSString stringWithFormat:@"%.1f", num];
    }
    return [NSString stringWithFormat:@"%.0f", num];
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

+ (void)createPathIfNotExist:(NSString *)path {
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]){
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:true attributes:nil error:nil];
    }
}
+ (NSInteger)fileSizeWithPath:(NSString *)path {
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) return 0;
    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return dic ? (NSInteger)[dic fileSize] : 0;
}

@end


@implementation YCDownloadDB

static sqlite3 *_db;
static dispatch_queue_t _dbQueue;

+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self initDatabase];
    });
}

+ (void)initDatabase{
    _dbQueue = dispatch_queue_create("YCDownloadDB_Queue", DISPATCH_QUEUE_SERIAL);
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
    path = [path stringByAppendingPathComponent:@"download.db"];
    if (sqlite3_open(path.UTF8String, &_db) != SQLITE_OK) {
        NSLog(@"[db error]");
        return;
    }
    NSString *sql = @"CREATE TABLE IF NOT EXISTS downloadItem (pid integer PRIMARY KEY AUTOINCREMENT,fileId text,taskId text,downloadUrl text,uid text,fileType text,fileExtension text,rootPath text,fileSize integer,downloadSize integer,downloadStatus integer,extraData blob); \n"
    "CREATE TABLE IF NOT EXISTS downloadTask (pid integer PRIMARY KEY AUTOINCREMENT,fileId text,taskId text,downloadUrl text,stid integer,saveName text,priority float,enableSpeed bool,fileSize INTEGER,downloadSize INTEGER,compatibleKey text,resumeData blob);";
    [self performBlock:^BOOL{ return [self execSql:sql]; } sync:true] ? NSLog(@"[init db success]") : false;
}

+ (BOOL)performBlock:(BOOL (^)(void))block sync:(BOOL)sync {
    __block BOOL result = false;
    if (sync) {
        dispatch_sync(_dbQueue, ^{
            result = block();
        });
    }else{
        dispatch_async(_dbQueue, ^{
            block();
        });
        result = true;
    }
    return result;
}

+ (BOOL)execSql:(NSString *)sql {
    char *error = NULL;
    sqlite3_exec(_db, sql.UTF8String, NULL, NULL, &error);
    error ? NSLog(@"[execSql error] %s", error) : false;
    return error == NULL;
}
//while (sqlite3_step(stmt) == SQLITE_ROW) {}
+ (void)selectSql:(NSString *)sql results:(void (^)(sqlite3_stmt *stmt))results {
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(_db, sql.UTF8String, -1, &stmt, NULL) == SQLITE_OK) {
        results(stmt);
    }
}

+ (NSArray <YCDownloadItem *> *)fetchAllDownloadItem {
    return nil;
}
+ (NSArray <YCDownloadItem *> *)fetchAllDownloadedItem {
    return nil;
}
+ (NSArray <YCDownloadItem *> *)fetchAllDownloadingItem {
    return nil;
}
+ (YCDownloadItem *)itemWithTaskId:(NSString *)taskId {
    return nil;
}
+ (YCDownloadItem *)itemWithUrl:(NSString *)downloadUrl {
    return nil;
}
+ (YCDownloadItem *)itemWithFid:(NSString *)fid {
    return nil;
}
+ (void)removeAllItems {
    
}
+ (BOOL)removeItemWithTaskId:(NSString *)taskId {
    return true;
}
+ (BOOL)saveItem:(YCDownloadItem *)item {
    return true;
}

+ (NSArray <YCDownloadTask *> *)fetchAllDownloadTasks {
    return nil;
}
+ (YCDownloadTask *)taskWithTid:(NSString *)tid {
    return nil;
}
+ (NSArray <YCDownloadTask *> *)taskWithUrl:(NSString *)url {
    return nil;
}
+ (YCDownloadTask *)taskWithStid:(NSInteger)stid {
    return nil;
}
+ (void)removeAllTasks {
    
}
+ (void)removeTask:(YCDownloadTask *)task {

}
+ (BOOL)saveTask:(YCDownloadTask *)task {
    return true;
}

@end
