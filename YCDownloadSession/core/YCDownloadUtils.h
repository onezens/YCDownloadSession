//
//  YCDownloadUtils.h
//  YCDownloadSession
//
//  Created by wz on 2018/6/22.
//  Copyright © 2018年 onezen.cc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define YC_DEVICE_VERSION [[[UIDevice currentDevice] systemVersion] floatValue]

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

@interface YCDownloadUtils : NSObject

/**
 获取当前手机的空闲磁盘空间
 */
+ (int64_t)fileSystemFreeSize;

/**
 将文件的字节大小，转换成更加容易识别的大小KB，MB，GB
 */
+ (NSString *)fileSizeStringFromBytes:(int64_t)byteSize;

/**
 字符串md5加密
 
 @param string 需要MD5加密的字符串
 @return MD5后的值
 */
+ (NSString *)md5ForString:(NSString *)string;

/**
 创建路径
 */
+ (void)createPathIfNotExist:(NSString *)path;

+ (int64_t)fileSizeWithPath:(NSString *)path;

+ (NSString *)urlStrWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask;

+ (NSUInteger)sec_timestamp;

@end

#import "YCDownloadTask.h"

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
