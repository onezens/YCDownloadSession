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
    if (str == NULL) str = "";
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
+ (NSUInteger)fileSizeWithPath:(NSString *)path {
    if(![[NSFileManager defaultManager] fileExistsAtPath:path]) return 0;
    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    return dic ? (NSUInteger)[dic fileSize] : 0;
}

@end

@interface YCDownloadItem(YCDownloadDB)
@property (nonatomic, assign) NSInteger pid;
@property (nonatomic, copy) NSString *fileExtension;
@property (nonatomic, copy) NSString *rootPath;
+ (instancetype)itemWithDict:(NSDictionary *)dict;

@end

@interface YCDownloadTask(YCDownloadDB)
@property (nonatomic, assign) NSInteger pid;
+ (instancetype)taskWithDict:(NSDictionary *)dict;
@end

typedef NS_ENUM(NSUInteger, YCDownloadDBValueType) {
    YCDownloadDBValueTypeNull,
    YCDownloadDBValueTypeString,
    YCDownloadDBValueTypeNumber,
    YCDownloadDBValueTypeData
};

@implementation YCDownloadDB

static sqlite3 *_db;
static dispatch_queue_t _dbQueue;
static const char* allItemKeys[] = {"fileId", "taskId", "downloadURL", "uid", "fileType", "fileExtension", "rootPath", "fileSize", "downloadedSize", "downloadStatus", "extraData"};
static const char* allTaskKeys[] = {"taskId", "downloadURL", "stid", "priority", "enableSpeed", "fileSize", "downloadedSize", "compatibleKey", "tmpName" };

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
    NSString *sql = @"CREATE TABLE IF NOT EXISTS downloadItem (pid integer PRIMARY KEY AUTOINCREMENT,taskId text not null unique,fileId text unique, downloadURL text,uid text,fileType text,fileExtension text,rootPath text,fileSize integer,downloadedSize integer,downloadStatus integer,extraData BLOB); \n"
    "CREATE TABLE IF NOT EXISTS downloadTask (pid integer PRIMARY KEY AUTOINCREMENT,taskId text not null unique,downloadURL text,stid integer, text,priority float,enableSpeed integer,fileSize INTEGER,downloadedSize INTEGER,compatibleKey text,resumeData BLOB,tmpName text);";
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

+ (id)objectWithStmt:(sqlite3_stmt *)stmt idx:(int)idx {
    int type = sqlite3_column_type(stmt, idx);
    id ocObj = nil;
    switch (type) {
        case SQLITE_INTEGER:
            ocObj = [NSNumber numberWithInteger:sqlite3_column_int(stmt, idx)];
            break;
        case SQLITE_FLOAT:
            ocObj = [NSNumber numberWithDouble:sqlite3_column_double(stmt, idx)];
            break;
        case SQLITE_BLOB:
        {
            const char *dataBuffer = sqlite3_column_blob(stmt, idx);
            int dataSize = sqlite3_column_bytes(stmt, idx);
            ocObj = [NSData dataWithBytes:dataBuffer length:dataSize];
        }
            break;
        case SQLITE_NULL:
            break;
        default:
        {
            const char *value = (const char *)sqlite3_column_text(stmt, idx);
            ocObj = [[NSString alloc] initWithUTF8String:value];
        }
            break;
    }
    return ocObj;
}

+ (NSArray *)selectSql:(NSString *)sql {
    NSMutableArray *arrM;
    sqlite3_stmt *stmt;
    if (sqlite3_prepare_v2(_db, sql.UTF8String, -1, &stmt, NULL) == SQLITE_OK) {
        arrM = [NSMutableArray array];
        while (sqlite3_step(stmt) == SQLITE_ROW) {
            NSMutableDictionary *dictM = [NSMutableDictionary dictionary];
            int count = sqlite3_column_count(stmt);
            for (int i=0; i<count; i++) {
                const char *key = sqlite3_column_name(stmt, i);
                id ocObj = [self objectWithStmt:stmt idx:i];
                [dictM setValue:ocObj forKey:[[NSString alloc] initWithUTF8String:key]];
            }
            [arrM addObject:dictM];
        }
    }
    return arrM;
}

+ (void)execTransactionSql:(NSArray *)sqls{
    @try{
        char *error;
        if (sqlite3_exec(_db, "BEGIN", NULL, NULL, &error)==SQLITE_OK) {
            NSLog(@"启动事务成功");
            sqlite3_free(error);
            sqlite3_stmt *statement;
            for (int i = 0; i<sqls.count; i++) {
                if (sqlite3_prepare_v2(_db,[[sqls objectAtIndex:i] UTF8String], -1, &statement,NULL)==SQLITE_OK) {
                    if (sqlite3_step(statement)!=SQLITE_DONE) sqlite3_finalize(statement);
                }
            }
            if (sqlite3_exec(_db, "COMMIT", NULL, NULL, &error)==SQLITE_OK)   NSLog(@"提交事务成功");
            sqlite3_free(error);
        }
        else sqlite3_free(error);
    } @catch(NSException *e) {
        char *error;
        if (sqlite3_exec(_db, "ROLLBACK", NULL, NULL, &error)==SQLITE_OK)  NSLog(@"回滚事务成功");
        sqlite3_free(error);
    }
}

+ (NSArray <YCDownloadItem *> *)fetchAllDownloadItem {
    __block NSMutableArray *results = [NSMutableArray array];
    [self performBlock:^BOOL{
        NSArray *rel = [self selectSql:@"select * from downloadItem"];
        [rel enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            YCDownloadItem *item = [YCDownloadItem itemWithDict:obj];
            [results addObject:item];
        }];
        return true;
    } sync:true];
    return results;
}

+ (NSArray <YCDownloadItem *> *)fetchAllDownloadedItem {
    __block NSMutableArray *results = [NSMutableArray array];
    [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"select * from downloadItem where downloadStatus == %ld", YCDownloadStatusFinished];
        NSArray *rel = [self selectSql:sql];
        [rel enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            YCDownloadItem *item = [YCDownloadItem itemWithDict:obj];
            [results addObject:item];
        }];
        return true;
    } sync:true];
    return results;
}
+ (NSArray <YCDownloadItem *> *)fetchAllDownloadingItem {
    __block NSMutableArray *results = [NSMutableArray array];
    [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"select * from downloadItem where downloadStatus != %ld", YCDownloadStatusFinished];
        NSArray *rel = [self selectSql:sql];
        [rel enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            YCDownloadItem *item = [YCDownloadItem itemWithDict:obj];
            [results addObject:item];
        }];
        return true;
    } sync:true];
    return results;
}
+ (YCDownloadItem *)itemWithTaskId:(NSString *)taskId {
    __block YCDownloadItem *item = nil;
    [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"select * from downloadItem where taskId == '%@'", taskId];
        NSArray *rel = [self selectSql:sql];
        item = [YCDownloadItem itemWithDict:rel.firstObject];
        return true;
    } sync:true];
    return item;
}
+ (YCDownloadItem *)itemWithUrl:(NSString *)downloadUrl {
    __block YCDownloadItem *item = nil;
    [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"select * from downloadItem where downloadURL == '%@'", downloadUrl];
        NSArray *rel = [self selectSql:sql];
        item = [YCDownloadItem itemWithDict:rel.firstObject];
        return true;
    } sync:true];
    return item;
}
+ (YCDownloadItem *)itemWithFid:(NSString *)fid {
    __block YCDownloadItem *item = nil;
    [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"select * from downloadItem where fileId == '%@'", fid];
        NSArray *rel = [self selectSql:sql];
        item = [YCDownloadItem itemWithDict:rel.firstObject];
        return true;
    } sync:true];
    return item;
}
+ (void)removeAllItems {
    [self performBlock:^BOOL{
        return [self execSql:@"delete from downloadItem"];
    } sync:false];
}
+ (BOOL)removeItemWithTaskId:(NSString *)taskId {
    return [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"delete from downloadItem where taskId == '%@'", taskId];
        return [self execSql:sql];
    } sync:true];
}

+ (YCDownloadDBValueType)getTypeWithValue:(id)value {
    YCDownloadDBValueType type = YCDownloadDBValueTypeNull;
    if ([value isKindOfClass:[NSString class]]) {
        type = YCDownloadDBValueTypeString;
    }else if ([value isKindOfClass:[NSNumber class]]){
        type = YCDownloadDBValueTypeNumber;
    }else if ([value isKindOfClass:[NSData class]]){
        type = YCDownloadDBValueTypeData;
    }
    return type;
}

+ (void)getSqlWithKeys:(const char **)keys count:(int)count  obj:(id)obj oldItem:(NSDictionary *)oldItem enumerateBlock:(void (^)(YCDownloadDBValueType type, NSString *key, id value,  int idx))enumerateBlock{
    for (int i=0; i<count; i++) {
        YCDownloadDBValueType type = YCDownloadDBValueTypeNull;
        NSString *key = [NSString stringWithUTF8String:keys[i]];
        id value = [obj valueForKey:[NSString stringWithFormat:@"_%@", key]];
        BOOL isEqual = false;
        id oValue = [oldItem valueForKey:key];
        if ([value isKindOfClass:[NSString class]]) {
            isEqual = oValue && [value isEqualToString:oValue];
            type = YCDownloadDBValueTypeString;
        }else if ([value isKindOfClass:[NSNumber class]]){
            isEqual = (oValue && [value isEqualToNumber:oValue]) || (oValue==nil && [value isEqualToNumber:@0]);
            type = YCDownloadDBValueTypeNumber;
        }else if ([value isKindOfClass:[NSData class]]){
            isEqual = oValue && [value isEqualToData:oValue];
            type = YCDownloadDBValueTypeData;
        }else if(value != oValue){
            isEqual = false;
        }else{
            NSAssert(value==nil && oValue==nil, @"cls err");
        }
        if (!isEqual) {
            enumerateBlock(value ? type : [self getTypeWithValue:oValue], key, value, i);
        }
    }
}

+ (BOOL)updateItemExtraData:(YCDownloadItem *)item {
    return true;
}

+ (BOOL)updateItem:(YCDownloadItem *)item withResults:(NSArray *)results {
    NSMutableString *updateSql = [NSMutableString string];
    int count = sizeof(allItemKeys) / sizeof(allItemKeys[0]);
    [self getSqlWithKeys:allItemKeys count:count obj:item oldItem:results.firstObject enumerateBlock:^(YCDownloadDBValueType type, NSString *key, id value, int idx) {
        if (type == YCDownloadDBValueTypeData) {
            [self updateItemExtraData:item];
        }else if (type == YCDownloadDBValueTypeNumber){
            [updateSql appendFormat:@"%@%@=%@", updateSql.length !=0 ? @", " : @"", key, [value stringValue]];
        }else if(type == YCDownloadDBValueTypeNull){
            [updateSql appendFormat:@"%@%@=null",updateSql.length !=0 ? @", " : @"", key];
        }else{
            NSAssert([value isKindOfClass:[NSString class]], @"cls error");
            [updateSql appendFormat:@"%@%@='%@'",updateSql.length !=0 ? @", " : @"",  key, value];
        }
    }];
    if(updateSql.length>0){
        NSString *sql = [NSString stringWithFormat:@"update downloadItem set %@ where taskId == '%@'", updateSql, item.taskId];
        return [self execSql:sql];
    }
    return true;
}

+ (BOOL)saveItem:(YCDownloadItem *)item {
    return [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"select * from downloadItem WHERE taskId == '%@'", item.taskId];
        NSArray *results = [self selectSql:sql];
        BOOL result = false;
        if (results.count==0) {
            NSMutableString *insertSqlKeys = [NSMutableString string];
            NSMutableString *insertSqlValues = [NSMutableString string];
            int count = sizeof(allItemKeys) / sizeof(allItemKeys[0]);
            [self getSqlWithKeys:allItemKeys count:count obj:item oldItem:nil enumerateBlock:^(YCDownloadDBValueType type, NSString *key, id value, int idx) {
                if (type == YCDownloadDBValueTypeNumber){
                    [insertSqlKeys appendFormat:@"%@%@", insertSqlKeys.length!=0 ? @", ": @"", key];
                    [insertSqlValues appendFormat:@"%@%@", insertSqlValues.length!=0 ? @", " : @"", [value stringValue]];
                }else if(type == YCDownloadDBValueTypeString){
                    [insertSqlKeys appendFormat:@"%@%@", insertSqlKeys.length!=0 ? @", ": @"", key];
                    [insertSqlValues appendFormat:@"%@'%@'", insertSqlValues.length!=0 ? @", " : @"", value];
                }
            }];
            sql = [NSString stringWithFormat:@"insert into downloadItem(%@) VALUES(%@)", insertSqlKeys, insertSqlValues];
            result = [self execSql:sql];
            if(result && item.extraData){
                NSString *sql_data = [NSString stringWithFormat:@"update downloadItem set extraData=? where taskId == '%@'", item.taskId];
                sqlite3_stmt *stmt = NULL;
                if (sqlite3_prepare_v2(_db, [sql_data UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
                    sqlite3_bind_blob64(stmt, 1, [item.extraData bytes], [item.extraData length], NULL);
                    if (sqlite3_step(stmt) == SQLITE_DONE) {
                        NSLog(@"data success");
                        return result;
                    }
                }
                result = false;
            }
        }else{
            result = [self updateItem:item withResults:results];
        }
        return result;
    } sync:true];
}

+ (NSArray <YCDownloadTask *> *)fetchAllDownloadTasks {
    __block NSMutableArray *results = [NSMutableArray array];
    [self performBlock:^BOOL{
        NSArray *rel = [self selectSql:@"select * from downloadItem"];
        [rel enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            YCDownloadTask *task = [YCDownloadTask taskWithDict:obj];
            [results addObject:task];
        }];
        return true;
    } sync:true];
    return results;
}
+ (YCDownloadTask *)taskWithTid:(NSString *)tid {
    __block YCDownloadTask *task = nil;
    [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"select * from downloadTask where taskId == '%@'", tid];
        NSArray *rel = [self selectSql:sql];
        task = [YCDownloadTask taskWithDict:rel.firstObject];
        return true;
    } sync:true];
    return task;
}

+ (NSArray <YCDownloadTask *> *)taskWithUrl:(NSString *)url {
    return nil;
}

+ (YCDownloadTask *)taskWithStid:(NSInteger)stid {
    __block YCDownloadTask *task = nil;
    [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"select * from downloadTask where stid == %zd", stid];
        NSArray *rel = [self selectSql:sql];
        task = [YCDownloadTask taskWithDict:rel.firstObject];
        return true;
    } sync:true];
    return task;
}

+ (void)removeAllTasks {
    [self performBlock:^BOOL{
        return [self execSql:@"delete from downloadTask"];
    } sync:false];
}

+ (BOOL)removeTask:(YCDownloadTask *)task {
    return [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"delete from downloadTask where taskId == '%@'", task.taskId];
        return [self execSql:sql];
    } sync:false];
}



+ (BOOL)updateTask:(YCDownloadTask *)task withResults:(NSArray *)results {
    NSMutableString *updateSql = [NSMutableString string];
    int count = sizeof(allTaskKeys) /sizeof(allTaskKeys[0]);
    [self getSqlWithKeys:allTaskKeys count:count obj:task oldItem:results.firstObject enumerateBlock:^(YCDownloadDBValueType type, NSString *key, id value, int idx) {
        if (type == YCDownloadDBValueTypeData) {
            [self updateResumeDataWithTask:task];
        }else if (type == YCDownloadDBValueTypeNumber){
            [updateSql appendFormat:@"%@%@=%@", updateSql.length !=0 ? @", " : @"", key, [value stringValue]];
        }else if(type == YCDownloadDBValueTypeNull){
            [updateSql appendFormat:@"%@%@=null",updateSql.length !=0 ? @", " : @"", key];
        }else{
            NSAssert([value isKindOfClass:[NSString class]], @"cls error");
            [updateSql appendFormat:@"%@%@='%@'",updateSql.length !=0 ? @", " : @"",  key, value];
        }
    }];
    if (updateSql.length>0) {
        NSString *sql = [NSString stringWithFormat:@"update downloadTask set %@ where taskId == '%@'", updateSql, task.taskId];
        return [self execSql:sql];
    }
    return true;
}

+ (BOOL)updateResumeDataWithTask:(YCDownloadTask *)task {
    BOOL result = false;
    NSString *sql_data = [NSString stringWithFormat:@"update downloadTask set resumeData=? where taskId == '%@'", task.resumeData];
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(_db, [sql_data UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
        sqlite3_bind_blob64(stmt, 1, [task.resumeData bytes], [task.resumeData length], NULL);
        if (sqlite3_step(stmt) == SQLITE_DONE) {
            NSLog(@"task resumedata success");
            return result;
        }
    }
    return result;
}

+ (BOOL)saveTask:(YCDownloadTask *)task {
    return [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"select * from downloadTask WHERE taskId == '%@'", task.taskId];
        NSArray *results = [self selectSql:sql];
        BOOL result = false;
        if (results.count==0) {
            NSMutableString *insertSqlKeys = [NSMutableString string];
            NSMutableString *insertSqlValues = [NSMutableString string];
            int count = sizeof(allTaskKeys) / sizeof(allTaskKeys[0]);
            [self getSqlWithKeys:allTaskKeys count:count obj:task oldItem:nil enumerateBlock:^(YCDownloadDBValueType type, NSString *key, id value, int idx) {
                if (type == YCDownloadDBValueTypeNumber){
                    [insertSqlKeys appendFormat:@"%@%@", insertSqlKeys.length!=0 ? @", ": @"", key];
                    [insertSqlValues appendFormat:@"%@%@", insertSqlValues.length!=0 ? @", " : @"", [value stringValue]];
                }else if(type == YCDownloadDBValueTypeString){
                    [insertSqlKeys appendFormat:@"%@%@", insertSqlKeys.length!=0 ? @", ": @"", key];
                    [insertSqlValues appendFormat:@"%@'%@'", insertSqlValues.length!=0 ? @", " : @"", value];
                }
            }];
            sql = [NSString stringWithFormat:@"insert into downloadTask(%@) VALUES(%@)", insertSqlKeys, insertSqlValues];
            result = [self execSql:sql];
            if(result && task.resumeData){
                result = [self updateResumeDataWithTask:task];
            }
        }else{
            result = [self updateTask:task withResults:results];
        }
        return result;
    } sync:true];
}

@end
