//
//  YCDownloadDB.h
//  YCDownloadSession
//
//  Created by wz on 2018/6/26.
//  Copyright © 2018年 onezen.cc. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "YCDownloadItem.h"

@interface YCDownloadDB : NSObject
@property (nonatomic, strong) NSManagedObjectContext *context;
+ (instancetype)sharedDB;
- (BOOL)save;
- (NSArray <YCDownloadItem *> *)fetchAllDownloadItem;
- (NSArray <YCDownloadItem *> *)fetchAllDownloadedItem;
- (NSArray <YCDownloadItem *> *)fetchAllDownloadingItem;
- (YCDownloadItem *)itemWithTaskId:(NSString *)taskId;
- (YCDownloadItem *)itemWithUrl:(NSString *)downloadUrl;
- (YCDownloadItem *)itemWithFid:(NSString *)fid;
- (BOOL)removeItemWithTaskId:(NSString *)taskId;
- (void)removeAllItems;

@end
