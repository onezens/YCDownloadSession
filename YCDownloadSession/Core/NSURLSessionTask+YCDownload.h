//
//  NSURLSessionDownloadTask+YCDownload.h
//  YCDownloadSession
//
//  Created by wz on 2024/2/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class YCDownloadTask;

@interface NSURLSessionTask (YCDownload)

@property (nonatomic, weak) YCDownloadTask *ycTask;

@end

NS_ASSUME_NONNULL_END
