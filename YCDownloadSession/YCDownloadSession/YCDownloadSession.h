//
//  YCDownloadSession.h
//  YCDownloadSession
//
//  Created by wangzhen on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol YCDownloadSessionDelegate <NSObject>


@end

@interface YCDownloadSession : NSObject

@property (nonatomic, weak) id <YCDownloadSessionDelegate>delegate;

+ (instancetype)downloadSession;

- (void)startDownloadWithURL:(NSString *)downloadUrl;

@end
