//
//  YCDownloadSession.h
//  Pods-YCDownloadSession
//
//  Created by wz on 2022/2/25.
//

#import <Foundation/Foundation.h>
#import <YCDownloadSession/YCdownloadTask.h>
#import <YCDownloadSession/YCDownloadSessionConfig.h>

NS_ASSUME_NONNULL_BEGIN

@interface YCDownloadSession : NSObject

+ (instancetype)sharedSession;

+ (instancetype)sessionWithConfiguration:(YCDownloadSessionConfig *)config;

- (YCDownloadTask *)taskWithURL:(NSURL *)URL;

- (YCDownloadTask *)taskWithUrlStr:(NSString *)url;

- (YCDownloadTask *)taskWithRequest:(NSURLRequest *)request;

@end

NS_ASSUME_NONNULL_END
