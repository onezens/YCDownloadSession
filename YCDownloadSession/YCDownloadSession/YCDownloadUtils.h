//
//  YCDownloadUtils.h
//  YCDownloadSession
//
//  Created by wz on 2018/6/22.
//  Copyright © 2018年 onezen.cc. All rights reserved.
//

#import <Foundation/Foundation.h>

#define YC_DEVICE_VERSION [[[UIDevice currentDevice] systemVersion] floatValue]

@interface YCDownloadUtils : NSObject

/**
 获取当前手机的空闲磁盘空间
 */
+ (NSUInteger)fileSystemFreeSize;

/**
 将文件的字节大小，转换成更加容易识别的大小KB，MB，GB
 */
+ (NSString *)fileSizeStringFromBytes:(NSUInteger)byteSize;

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

+ (NSInteger)fileSizeWithPath:(NSString *)path;

@end


#import "YCDownloadItem.h"
#import "YCDownloadTask.h"

@interface YCDownloadDB : NSObject

+ (NSArray <YCDownloadItem *> *)fetchAllDownloadItem;
+ (NSArray <YCDownloadItem *> *)fetchAllDownloadedItem;
+ (NSArray <YCDownloadItem *> *)fetchAllDownloadingItem;
+ (YCDownloadItem *)itemWithTaskId:(NSString *)taskId;
+ (YCDownloadItem *)itemWithUrl:(NSString *)downloadUrl;
+ (YCDownloadItem *)itemWithFid:(NSString *)fid;
+ (void)removeAllItems;
+ (BOOL)removeItemWithTaskId:(NSString *)taskId;
+ (BOOL)saveItem:(YCDownloadItem *)item;

+ (NSArray <YCDownloadTask *> *)fetchAllDownloadTasks;
+ (YCDownloadTask *)taskWithTid:(NSString *)tid;
+ (NSArray <YCDownloadTask *> *)taskWithUrl:(NSString *)url;
+ (YCDownloadTask *)taskWithStid:(NSInteger)stid; //TODO: add url
+ (void)removeAllTasks;
+ (void)removeTask:(YCDownloadTask *)task;
+ (BOOL)saveTask:(YCDownloadTask *)task;
@end
