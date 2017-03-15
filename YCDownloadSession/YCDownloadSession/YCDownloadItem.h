//
//  YCDownloadItem.h
//  YCDownloadSession
//
//  Created by wangzhen on 17/3/15.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YCDownloadItem : NSObject

@property (nonatomic, copy) NSString *downloadURL;
@property (nonatomic, strong) NSData *resumeData;
@property (nonatomic, strong) NSURLSessionDownloadTask *downloadTask;

@property (nonatomic, copy, readonly) NSString *suggestedFilename;
@property (nonatomic, copy, readonly) NSString *savePath;
@property (nonatomic, assign, readonly) long long fileSize;
@property (nonatomic, strong, readonly) NSURLResponse *response;


+ (NSString *)getURLFromTask:(NSURLSessionTask *)task;

- (void)updateItem;

@end
