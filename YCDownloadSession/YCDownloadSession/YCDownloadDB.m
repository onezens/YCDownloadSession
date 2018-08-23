//
//  YCDownloadDB.m
//  YCDownloadSession
//
//  Created by wz on 2018/6/26.
//  Copyright © 2018年 onezen.cc. All rights reserved.
//

#import "YCDownloadDB.h"
#import "YCDownloadItem.h"

@interface YCDownloadDB()

@end

@implementation YCDownloadDB

+ (instancetype)sharedDB {
    static YCDownloadDB *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [YCDownloadDB new];
        [_instance initContext];
    });
    return _instance;
}

- (void)initContext {
    NSURL *docUrl = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
    NSURL *storeURL = [docUrl URLByAppendingPathComponent:@"YCDownload.sqlite"];
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"YCDownload" withExtension:@"momd"];
    NSManagedObjectModel *managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSError *error = nil;
    NSPersistentStoreCoordinator *persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"[YCDownloadDB initContext] Error: %@", error);
        abort();
    }
    _context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_context setPersistentStoreCoordinator:persistentStoreCoordinator];
    [_context setRetainsRegisteredObjects:YES];
}

- (BOOL)performTask:(BOOL (^)(void))task sync:(BOOL)sync {
    if (sync) {
        __block BOOL result;
        [_context performBlockAndWait:^{ result = task(); }];
        return result;
    }else{
        [_context performBlock:^{ task(); }];
        return YES;
    }
}

- (BOOL)save {
    if (![_context hasChanges]) return YES;
    NSError *localError = nil;
    BOOL result = false;
    @try { result = [_context save:&localError]; } @catch (NSException *exception) {}
    if (!result) {
        NSLog(@"[YCDownloadDB save] core data save error: %@", localError);
        [_context rollback];
    }
    return result;
}

- (NSArray *)fetchAllDownloadItem {
    __block NSArray *items = nil;
    [self performTask:^BOOL{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kDownloadItemStoreEntity];
        NSError *error = nil;
        NSArray *results = [self->_context executeFetchRequest:fetchRequest error:&error];
        if (error) return false;
        items = results;
        return true;
    } sync:true];
    return items;
}

- (NSArray *)fetchAllDownloadedItem {
    __block NSArray *items = nil;
    [self performTask:^BOOL{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kDownloadItemStoreEntity];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"downloadStatus == %d",YCDownloadStatusFinished];
        NSError *error = nil;
        NSArray *results = [self->_context executeFetchRequest:fetchRequest error:&error];
        if (error) return false;
        items = results;
        return true;
    } sync:true];
    return items;
}
- (NSArray *)fetchAllDownloadingItem {
    __block NSArray *items = nil;
    [self performTask:^BOOL{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kDownloadItemStoreEntity];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"downloadStatus != %d",YCDownloadStatusFinished];
        NSError *error = nil;
        NSArray *results = [self->_context executeFetchRequest:fetchRequest error:&error];
        if (error) return false;
        items = results;
        return true;
    } sync:true];
    return items;
}
- (YCDownloadItem *)itemWithTaskId:(NSString *)taskId {
    __block YCDownloadItem *item = nil;
    [self performTask:^BOOL{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kDownloadItemStoreEntity];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"taskId == %@",taskId];
        NSError *error = nil;
        NSArray *results = [self->_context executeFetchRequest:fetchRequest error:&error];
        if (error) return false;
        item = results.firstObject;
        return true;
    } sync:true];
    return item;
}
- (YCDownloadItem *)itemWithUrl:(NSString *)downloadUrl {
    __block YCDownloadItem *item = nil;
    [self performTask:^BOOL{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kDownloadItemStoreEntity];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"downloadUrl == %@",downloadUrl];
        NSError *error = nil;
        NSArray *results = [self->_context executeFetchRequest:fetchRequest error:&error];
        if (error) return false;
        item = results.firstObject;
        return true;
    } sync:true];
    return item;
}

- (YCDownloadItem *)itemWithFid:(NSString *)fid {
    __block YCDownloadItem *item = nil;
    [self performTask:^BOOL{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kDownloadItemStoreEntity];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"fileId == %@",fid];
        NSError *error = nil;
        NSArray *results = [self->_context executeFetchRequest:fetchRequest error:&error];
        if (error) return false;
        item = results.firstObject;
        return true;
    } sync:true];
    return item;
}

- (BOOL)removeItemWithTaskId:(NSString *)taskId {
    return [self performTask:^BOOL{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kDownloadItemStoreEntity];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"taskId == %@",taskId];
        NSError *error = nil;
        NSArray *results = [self->_context executeFetchRequest:fetchRequest error:&error];
        if (error) return false;
        YCDownloadItem *item = results.firstObject;
        if (item) {
            [self->_context deleteObject:item];
        }
        return [self save];;
    } sync:true];
}
- (void)removeAllItems {
    [self performTask:^BOOL{
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:kDownloadItemStoreEntity];
        NSError *error = nil;
        NSArray <YCDownloadItem *> *results = [self->_context executeFetchRequest:fetchRequest error:&error];
        if (error) return false;
        [results enumerateObjectsUsingBlock:^(YCDownloadItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self->_context deleteObject:obj];
        }];
        return [self save];;
    } sync:false];
}
@end
