//
//  YCDownloadDB.m
//  YCDownloadSession
//
//  Created by wz on 2019/4/3.
//  Copyright © 2019 onezen.cc. All rights reserved.
//

#import "YCDownloadDB.h"
#import "YCDownloadUtils.h"
#import <sqlite3.h>

#define kYCDownloadVersionKey @"YCDownloadVersionKey"
#define kYCDownloadDbMinUpgradeVerion @"2.0.2" //数据库的表和字段更新需要改变版本号

#if YCDownload_Mgr_Item
@interface YCDownloadItem(YCDownloadDB)
@property (nonatomic, assign) NSInteger pid;
@property (nonatomic, copy) NSString *fileExtension;
@property (nonatomic, copy) NSString *rootPath;
@property (nonatomic, assign, readonly) NSUInteger createTime;
+ (instancetype)itemWithDict:(NSDictionary *)dict;

@end
#endif

@interface YCDownloadTask(YCDownloadDB)
@property (nonatomic, assign) NSInteger pid;
@property (nonatomic, assign, readonly) NSUInteger createTime;
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
//tasks
static const char* allTaskKeys[] = {"taskId", "downloadURL", "stid", "priority", "fileSize", "downloadedSize", "version", "tmpName", "resumeData", "extraData", "createTime"};
static NSMutableDictionary <NSString* ,YCDownloadTask *> *_memCacheTasks;

#if YCDownload_Mgr_Item
//items
static const char* allItemKeys[] = {"fileId", "taskId", "downloadURL", "uid", "fileType", "fileExtension", "rootPath", "fileSize", "downloadedSize", "downloadStatus", "extraData", "version", "createTime", "enableSpeed"};
static NSMutableDictionary <NSString* ,YCDownloadItem *> *_memCacheItems;
#endif

#pragma mark - init db
+ (void)initialize {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self initDatabase];
    });
}

#pragma makr - db Handler
+ (void)initDatabase{
    _dbQueue = dispatch_queue_create("YCDownloadDB_Queue", DISPATCH_QUEUE_SERIAL);
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
    path = [path stringByAppendingPathComponent:@"YCDownload"];
    [YCDownloadUtils createPathIfNotExist:path];
    path = [path stringByAppendingPathComponent:@"YCDownload.db"];
    if (sqlite3_open(path.UTF8String, &_db) != SQLITE_OK) {
        NSLog(@"[db error]");
        return;
    }
    NSString *sql = @"CREATE TABLE IF NOT EXISTS downloadItem (pid integer PRIMARY KEY AUTOINCREMENT,taskId text not null unique,fileId text, downloadURL text,uid text,fileType text,fileExtension text,rootPath text,fileSize integer,downloadedSize integer,downloadStatus integer,extraData BLOB, version text not null, createTime integer); \n"
    "CREATE TABLE IF NOT EXISTS downloadTask (pid integer PRIMARY KEY AUTOINCREMENT,taskId text not null unique, downloadURL text, stid integer, priority float, enableSpeed integer, fileSize INTEGER, downloadedSize INTEGER, version text not null, tmpName text, resumeData BLOB, extraData BLOB, createTime integer);";
    
    [self performBlock:^BOOL{ return [self execSql:sql]; } sync:true] ? NSLog(@"[init db success]") : false;
    [self compatibleDatabase];
    _memCacheTasks = [NSMutableDictionary dictionary];
#if YCDownload_Mgr_Item
    _memCacheItems = [NSMutableDictionary dictionary];
#endif
}

//数据库表字段变更
+ (void)compatibleDatabase {
    NSString *localVersion = [[NSUserDefaults standardUserDefaults] valueForKey:kYCDownloadVersionKey];
    NSString *curVersion = [YCDownloadTask downloaderVerison];
    if ([curVersion compare:localVersion options:NSNumericSearch] == NSOrderedDescending){
        [[NSUserDefaults standardUserDefaults] setValue:curVersion forKey:kYCDownloadVersionKey];
        if ([kYCDownloadDbMinUpgradeVerion compare:localVersion options:NSNumericSearch] == NSOrderedDescending) {
            NSString *sql = @"ALTER table downloadItem add enableSpeed integer;";
            [self performBlock:^BOOL{ return [self execSql:sql]; } sync:true] ? NSLog(@"[compatible db success]") : false;
        }
    }
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
            ocObj = [NSNumber numberWithLongLong:sqlite3_column_int64(stmt, idx)];
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
            isEqual = true;
        }
        if (!isEqual) {
            enumerateBlock(value ? type : [self getTypeWithValue:oValue], key, value, i);
        }
    }
}

#pragma mark - Handler

+ (void)saveAllData {
    [self performBlock:^BOOL{
        //fixme: transaction
        [_memCacheTasks enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, YCDownloadTask * _Nonnull obj, BOOL * _Nonnull stop) {
            [self saveDownloadTask:obj];
        }];
#if YCDownload_Mgr_Item
        [_memCacheItems enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, YCDownloadItem * _Nonnull obj, BOOL * _Nonnull stop) {
            [self saveDownloadItem:obj];
        }];
#endif
        return true;
    } sync:false];
}


#pragma mark - item
#if YCDownload_Mgr_Item
+ (YCDownloadItem *)itemWithDict:(NSDictionary *)dict {
    if(!dict) return nil;
    NSString *taskId = [dict valueForKey:@"taskId"];
    NSAssert(taskId, @"taskId can not nil!");
    if(!taskId) return nil;
    YCDownloadItem *item = _memCacheItems[taskId];
    if (item && ![item.taskId isEqualToString:taskId]){
        _memCacheItems[taskId] = nil;
        return nil;
    }
    if (!item) {
        item = [YCDownloadItem itemWithDict:dict];
        _memCacheItems[taskId] = item;
    }
    
    return item;
}

+ (NSArray <YCDownloadItem *> *)fetchAllDownloadItemWithUid:(NSString *)uid {
    __block NSMutableArray *results = [NSMutableArray array];
    [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"select * from downloadItem where uid == '%@' ORDER BY createTime",uid];
        NSArray *rel = [self selectSql:sql];
        [rel enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            YCDownloadItem *item = [self itemWithDict:obj];
            if(item) [results addObject:item];
        }];
        return true;
    } sync:true];
    return results;
}

+ (NSArray <YCDownloadItem *> *)fetchAllDownloadedItemWithUid:(NSString *)uid {
    __block NSMutableArray *results = [NSMutableArray array];
    [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"select * from downloadItem where downloadStatus == %lu and uid == '%@' ORDER BY createTime", (unsigned long)YCDownloadStatusFinished, uid];
        NSArray *rel = [self selectSql:sql];
        [rel enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            YCDownloadItem *item = [self itemWithDict:obj];
            if(item) [results addObject:item];
        }];
        return true;
    } sync:true];
    return results;
}

+ (NSArray <YCDownloadItem *> *)fetchAllDownloadingItemWithUid:(NSString *)uid {
    __block NSMutableArray *results = [NSMutableArray array];
    [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"select * from downloadItem where downloadStatus != %lu and uid == '%@' ORDER BY createTime",(unsigned long)YCDownloadStatusFinished, uid];
        NSArray *rel = [self selectSql:sql];
        [rel enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            YCDownloadItem *item = [self itemWithDict:obj];
            if(item) [results addObject:item];
        }];
        return true;
    } sync:true];
    return results;
}

+ (YCDownloadItem *)itemWithTaskId:(NSString *)taskId {
    __block YCDownloadItem *item = _memCacheItems[taskId];
    if(!item){
        [self performBlock:^BOOL{
            NSString *sql = [NSString stringWithFormat:@"select * from downloadItem where taskId == '%@'", taskId];
            NSArray *rel = [self selectSql:sql];
            item = [self itemWithDict:rel.firstObject];
            return true;
        } sync:true];
    }
    return item;
}

+ (NSArray *)itemsWithUrl:(NSString *)downloadUrl uid:(NSString *)uid{
    NSMutableArray *items = [NSMutableArray array];
    [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"select * from downloadItem where downloadURL == '%@' and uid == '%@'", downloadUrl, uid];
        NSArray *rel = [self selectSql:sql];
        [rel enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            YCDownloadItem *item = [self itemWithDict:rel.firstObject];
            if(item) [items addObject:item];
        }];
        
        return true;
    } sync:true];
    return items;
}

+ (YCDownloadItem *)itemWithFid:(NSString *)fid uid:(NSString *)uid{
    __block YCDownloadItem *item = nil;
    [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"select * from downloadItem where fileId == '%@' and uid == '%@'", fid, uid];
        NSArray *rel = [self selectSql:sql];
        item = [self itemWithDict:rel.firstObject];
        return true;
    } sync:true];
    return item;
}

+ (void)removeAllItemsWithUid:(NSString *)uid {
    [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"delete from downloadItem where uid == '%@'",uid];
        BOOL result = [self execSql:sql];
        if (result)  [_memCacheItems removeAllObjects];
        return result;
    } sync:false];
}

+ (BOOL)removeItemWithTaskId:(NSString *)taskId {
    if(!taskId) return true;
    return [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"delete from downloadItem where taskId == '%@'", taskId];
        BOOL result = [self execSql:sql];
        if(result) [_memCacheItems removeObjectForKey:taskId];
        return result;
    } sync:true];
}

+ (BOOL)updateItemExtraData:(YCDownloadItem *)item {
    BOOL result = false;
    NSString *sql_data = [NSString stringWithFormat:@"update downloadItem set extraData=? where taskId == '%@'", item.taskId];
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(_db, [sql_data UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
        sqlite3_bind_blob64(stmt, 1, [item.extraData bytes], [item.extraData length], NULL);
        if (sqlite3_step(stmt) == SQLITE_DONE) {
            return result;
        }
    }
    return result;
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

+ (BOOL)saveDownloadItem:(YCDownloadItem *)item {
    NSString *sql = [NSString stringWithFormat:@"select * from downloadItem WHERE taskId == '%@'", item.taskId];
    NSArray *results = [self selectSql:sql];
    BOOL result = false;
    if (results.count==0) {
        _memCacheItems[item.taskId] = item;
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
                    return result;
                }
            }
            result = false;
        }
    }else{
        result = [self updateItem:item withResults:results];
    }
    return result;
}

+ (BOOL)saveItem:(YCDownloadItem *)item {
    return [self performBlock:^BOOL{
        return [self saveDownloadItem:item];
    } sync:true];
}
#endif

#pragma mark - task

+ (YCDownloadTask *)taskWithDict:(NSDictionary *)dict {
    if(!dict) return nil;
    NSString *taskId = [dict valueForKey:@"taskId"];
    NSAssert(taskId, @"taskId can not nil!");
    if(!taskId) return nil;
    YCDownloadTask *task = [_memCacheTasks valueForKey:taskId];
    if (task && ![task.taskId isEqualToString:taskId]) {
        _memCacheTasks[taskId] = nil;
        return nil;
    }
    if (!task) {
        task = [YCDownloadTask taskWithDict:dict];
        _memCacheTasks[taskId] = task;
    }
    return task;
}

+ (YCDownloadTask *)taskWithTid:(NSString *)tid {
    if(!tid) return nil;
    __block YCDownloadTask *task = [_memCacheTasks valueForKey:tid];
    if(!task){
        [self performBlock:^BOOL{
            NSString *sql = [NSString stringWithFormat:@"select * from downloadTask where taskId == '%@'", tid];
            NSArray *rel = [self selectSql:sql];
            task = [self taskWithDict:rel.firstObject];
            return true;
        } sync:true];
    }
    return task;
}

+ (NSArray <YCDownloadTask *> *)taskWithUrl:(NSString *)url {
    NSMutableArray *tasks = [NSMutableArray array];
    [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"select * from downloadTask where downloadURL == '%@'", url];
        NSArray *rel = [self selectSql:sql];
        [rel enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            YCDownloadTask *task = [self taskWithDict:obj];
            [tasks addObject:task];
        }];
        return true;
    } sync:true];
    return tasks;
}

+ (NSArray *)taskWithStid:(NSInteger)stid {
    NSMutableArray *tasks = [NSMutableArray array];
    [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"select * from downloadTask where stid == %ld", (long)stid];
        NSArray *rel = [self selectSql:sql];
        [rel enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            YCDownloadTask *task = [self taskWithDict:rel.firstObject];
            [tasks addObject:task];
        }];
        return true;
    } sync:true];
    return tasks;
}

+ (void)removeAllTasks {
    [self performBlock:^BOOL{
        BOOL result = [self execSql:@"delete from downloadTask"];
        if(result) [_memCacheTasks removeAllObjects];
        return result;
    } sync:false];
}

+ (BOOL)removeTask:(YCDownloadTask *)task {
    if(!task) return true;
    return [self performBlock:^BOOL{
        NSString *sql = [NSString stringWithFormat:@"delete from downloadTask where taskId == '%@'", task.taskId];
        BOOL result = [self execSql:sql];
        if(result) [_memCacheTasks removeObjectForKey:task.taskId];
        return result;
    } sync:false];
}

+ (BOOL)updateTask:(YCDownloadTask *)task withResults:(NSArray *)results {
    NSMutableString *updateSql = [NSMutableString string];
    int count = sizeof(allTaskKeys) /sizeof(allTaskKeys[0]);
    [self getSqlWithKeys:allTaskKeys count:count obj:task oldItem:results.firstObject enumerateBlock:^(YCDownloadDBValueType type, NSString *key, id value, int idx) {
        if (type == YCDownloadDBValueTypeData) {
            if([key isEqualToString:@"extraData"]){
                [self updateTaskDataWithTid:task.taskId data:task.extraData dataKey:key];
            }else if ([key isEqualToString:@"resumeData"]){
                [self updateTaskDataWithTid:task.taskId data:task.resumeData dataKey:key];
            }else{
                NSLog(@"[Warn] new data key for task : %@", key);
            }
            
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

+ (BOOL)updateTaskDataWithTid:(NSString *)tid data:(NSData *)data dataKey:(NSString *)dataKey{
    BOOL result = false;
    NSString *sql = [NSString stringWithFormat:@"update downloadTask set %@=? where taskId == '%@'", dataKey,tid];
    sqlite3_stmt *stmt = NULL;
    if (sqlite3_prepare_v2(_db, [sql UTF8String], -1, &stmt, NULL) == SQLITE_OK) {
        sqlite3_bind_blob64(stmt, 1, [data bytes], [data length], NULL);
        if (sqlite3_step(stmt) == SQLITE_DONE) {
            return result;
        }
    }
    return result;
}
+ (NSArray <YCDownloadTask *> *)fetchAllDownloadTasks {
    __block NSMutableArray *results = [NSMutableArray array];
    [self performBlock:^BOOL{
        NSArray *rel = [self selectSql:@"select * from downloadTask"];
        [rel enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            YCDownloadTask *task = [self taskWithDict:obj];
            [results addObject:task];
        }];
        return true;
    } sync:true];
    return results;
}

+ (BOOL)saveDownloadTask:(YCDownloadTask *)task {
    NSString *sql = [NSString stringWithFormat:@"select * from downloadTask WHERE taskId == '%@'", task.taskId];
    NSArray *results = [self selectSql:sql];
    BOOL result = false;
    if (results.count==0) {
        _memCacheTasks[task.taskId] = task;
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
            result = [self updateTaskDataWithTid:task.taskId data:task.resumeData dataKey:@"resumeData"];
        }
        if (result && task.extraData) {
            result = [self updateTaskDataWithTid:task.taskId data:task.extraData dataKey:@"extraData"];
        }
    }else{
        result = [self updateTask:task withResults:results];
    }
    return result;
}

+ (BOOL)saveTask:(YCDownloadTask *)task {
    return [self performBlock:^BOOL{
        return [self saveDownloadTask:task];
    } sync:true];
}

@end
