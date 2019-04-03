//
//  YCDownloadDB.h
//  YCDownloadSession
//
//  Created by wz on 2019/4/3.
//  Copyright © 2019 onezen.cc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YCDownloadTask.h"

#ifndef YCDownload_Mgr_Item
#if __has_include(<YCDownloadItem.h>)
#define YCDownload_Mgr_Item 1
#import <YCDownloadItem.h>
#elif __has_include("YCDownloadItem.h")
#define YCDownload_Mgr_Item 1
#import "YCDownloadItem.h"
#else
#define YCDownload_Mgr_Item 0
#endif
#endif

@interface YCDownloadDB : NSObject

+ (NSArray <YCDownloadTask *> *)fetchAllDownloadTasks;
+ (YCDownloadTask *)taskWithTid:(NSString *)tid;
+ (NSArray <YCDownloadTask *> *)taskWithUrl:(NSString *)url;
+ (NSArray <YCDownloadTask *> *)taskWithStid:(NSInteger)stid; //TODO: add url
+ (void)removeAllTasks;
+ (BOOL)removeTask:(YCDownloadTask *)task;
+ (BOOL)saveTask:(YCDownloadTask *)task;
+ (void)saveAllData;

@end

#if YCDownload_Mgr_Item
@interface YCDownloadDB(item)
+ (NSArray <YCDownloadItem *> *)fetchAllDownloadItemWithUid:(NSString *)uid;
+ (NSArray <YCDownloadItem *> *)fetchAllDownloadedItemWithUid:(NSString *)uid;
+ (NSArray <YCDownloadItem *> *)fetchAllDownloadingItemWithUid:(NSString *)uid;
+ (NSArray <YCDownloadItem *> *)itemsWithUrl:(NSString *)downloadUrl uid:(NSString *)uid;
+ (YCDownloadItem *)itemWithTaskId:(NSString *)taskId;
+ (YCDownloadItem *)itemWithFid:(NSString *)fid uid:(NSString *)uid;
+ (void)removeAllItemsWithUid:(NSString *)uid;
+ (BOOL)removeItemWithTaskId:(NSString *)taskId;
+ (BOOL)saveItem:(YCDownloadItem *)item;
@end
#endif
