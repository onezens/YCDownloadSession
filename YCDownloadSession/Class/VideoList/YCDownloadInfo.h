//
//  YCDownloadInfo.h
//  YCDownloadSession
//
//  Created by wz on 2018/2/6.
//  Copyright © 2018年 onezen.cc. All rights reserved.
//

#import "YCDownloadItem.h"

@interface YCDownloadInfo : YCDownloadItem

@property (nonatomic, copy) NSString *desc;
@property (nonatomic, strong) NSDate *date;

@end
