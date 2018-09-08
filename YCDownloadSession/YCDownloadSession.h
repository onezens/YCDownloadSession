//
//  YCDownloadSession.h
//  YCDownloadSession
//
//  Created by wz on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//  Contact me: http://www.onezen.cc
//  Github:     https://github.com/onezens/YCDownloadSession
//
//

#ifndef YCDownload_H
#define YCDownload_H

#import "YCDownloader.h"
#import "YCDownloadUtils.h"

#ifndef YCDownload_Manager
#if __has_include(<YCDownloadManager.h>)
#define YCDownload_Manager 1
#import <YCDownloadManager.h>
#elif __has_include("YCDownloadManager.h")
#define YCDownload_Manager 1
#import "YCDownloadManager.h"
#else
#define YCDownload_Manager 0
#endif
#endif

#endif
