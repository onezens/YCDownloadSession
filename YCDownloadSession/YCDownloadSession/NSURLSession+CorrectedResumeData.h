//
//  NSURLSession+CorrectedResumeData.h
//  BackgroundDownloadDemo
//
//  Created by admin on 2016/10/12.
//  Copyright © 2016年 hkhust. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLSession (CorrectedResumeData)

- (NSURLSessionDownloadTask *)downloadTaskWithCorrectResumeData:(NSData *)resumeData;

@end
