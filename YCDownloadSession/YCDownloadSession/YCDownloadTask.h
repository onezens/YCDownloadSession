//
//  YCDownloadTask.h
//  YCDownloadSession
//
//  Created by wz on 17/3/15.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Contact me: http://www.onezen.cc
//  Github:     https://github.com/onezens/YCDownloadSession
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, YCDownloadStatus) {
    YCDownloadStatusWaiting,
    YCDownloadStatusDownloading,
    YCDownloadStatusPaused,
    YCDownloadStatusFinished,
    YCDownloadStatusFailed
};
#define IS_IOS10ORLATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10)
/**某一任务下载的状态发生变化的通知*/
static NSString * const kDownloadStatusChangedNoti = @"kDownloadStatusChangedNoti";

#pragma mark - YCDownloadTaskDelegate
@class YCDownloadTask;
@protocol YCDownloadTaskDelegate <NSObject>

@optional

/**
 下载任务的进度回调方法

 @param task 正在下载的任务
 @param downloadedSize 已经下载的文件大小
 @param fileSize 文件实际大小
 */
- (void)downloadProgress:(YCDownloadTask *)task downloadedSize:(NSUInteger)downloadedSize fileSize:(NSUInteger)fileSize;

/**
 下载任务第一次创建的时候的回调

 @param task 创建的任务
 */
- (void)downloadCreated:(YCDownloadTask *)task;

/**
 下载的任务的状态发生改变的回调

 @param status 改变后的状态
 @param task 状态改变的任务
 */
- (void)downloadStatusChanged:(YCDownloadStatus)status downloadTask:(YCDownloadTask *)task;

@end

#pragma mark - YCDownloadTask

@interface YCDownloadTask : NSObject

@property (nonatomic, readonly) NSString *taskId;
@property (nonatomic, copy, readonly) NSString *downloadURL;
/**文件标识，可以为空。要想同- downloadURL文件重复下载，可以让fileId不同*/
@property (nonatomic, copy, readonly) NSString *fileId;
@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, assign) YCDownloadStatus downloadStatus;
/**文件本地存储名称*/
@property (nonatomic, copy) NSString *saveName;
/**下载文件的存储路径，没有下载完成时，该路径下没有文件*/
@property (nonatomic, readonly) NSString *savePath;
/**判断文件是否下载完成，savePath路径下存在该文件为true，否则为false*/
@property (nonatomic, assign, readonly) BOOL downloadFinished;
@property (nonatomic, assign, readonly) NSInteger fileSize;
@property (nonatomic, assign) NSInteger downloadedSize;
/**重新创建下载session，恢复下载状态的session的标识*/
@property (nonatomic, assign) BOOL needToRestart;
/**
 是否支持断点续传
 */
@property (nonatomic, assign, readonly) BOOL isSupportRange;
/**
 是否 不需要下载下一个任务的标识，用来区分全部暂停和单个任务暂停后的操作
 */
@property (nonatomic, assign) BOOL noNeedToStartNext;
/** resumeData tmp name */
@property (nonatomic, copy) NSString *tmpName;
@property (nonatomic, copy) NSString *tempPath;
@property (nonatomic, weak) id <YCDownloadTaskDelegate>delegate;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic, copy) NSString *compatibleKey;


#pragma mark - method


/**
 初始化一个下载任务

 @param url 下载的url
 @param fileId 下载文件的标识。可以为空。要想同- downloadURL文件重复下载，可以让fileId不同
 @param delegate 代理
 @return 初始化的下载任务
 */
- (instancetype)initWithUrl:(NSString *)url fileId:(NSString *)fileId delegate:(id<YCDownloadTaskDelegate>)delegate;

/**
 初始化一个下载任务
 
 @param url 下载的url
 @param fileId 下载文件的标识。可以为空。要想同- downloadURL文件重复下载，可以让fileId不同
 @param delegate 代理
 @return 初始化的下载任务
 */
+ (instancetype)taskWithUrl:(NSString *)url fileId:(NSString *)fileId delegate:(id<YCDownloadTaskDelegate>)delegate;

/**
 下载进度第一次回调调用，保存文件大小信息
 */
- (void)updateTask;

/**
 继续下载任务
 */
- (void)resume;

/**
 暂停下载任务
 */
- (void)pause;

/**
 删除下载任务
 */
- (void)remove;

#pragma mark - class method
/**
 根据NSURLSessionTask获取下载的url
 301/302定向的originRequest和currentRequest的url不同，则取原始的
 */
+ (NSString *)getURLFromTask:(NSURLSessionTask *)task;

/**
 根据文件的名称获取文件的沙盒存储路径
 */
+ (NSString *)savePathWithSaveName:(NSString *)saveName;

/**
 获取文件的存储路径的目录
 */
+ (NSString *)saveDir;

/**
 字符串md5加密

 @param string 需要MD5加密的字符串
 @return MD5后的值
 */
+ (NSString *)md5ForString:(NSString *)string;


/**
 生成taskid

 @param url 资源url
 @param fileId 资源标识，可以为空
 @return taskid
 */
+ (NSString *)taskIdForUrl:(NSString *)url fileId:(NSString *)fileId;

@end


#pragma mark - YCResumeData
@interface YCResumeData: NSObject

@property (nonatomic, copy) NSString *downloadUrl;
@property (nonatomic, strong) NSMutableURLRequest *currentRequest;
@property (nonatomic, strong) NSMutableURLRequest *originalRequest;
@property (nonatomic, assign) NSInteger downloadSize;
@property (nonatomic, copy) NSString *resumeTag;
@property (nonatomic, assign) NSInteger resumeInfoVersion;
@property (nonatomic, strong) NSDate *downloadDate;
@property (nonatomic, copy) NSString *tempName;
@property (nonatomic, copy) NSString *resumeRange;

- (instancetype)initWithResumeData:(NSData *)resumeData;

+ (NSURLSessionDownloadTask *)downloadTaskWithCorrectResumeData:(NSData *)resumeData urlSession:(NSURLSession *)urlSession;

/**
 清除 NSURLSessionResumeByteRange 字段
 修正iOS11.0 iOS11.1 多次暂停继续 文件大小不对的问题(iOS11.2官方已经修复)
 
 @param resumeData 原始resumeData
 @return 清除后resumeData
 */
+ (NSData *)cleanResumeData:(NSData *)resumeData;
@end















