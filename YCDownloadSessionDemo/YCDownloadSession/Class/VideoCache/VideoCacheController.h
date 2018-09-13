//
//  VideoCacheController.h
//  YCDownloadSession
//
//  Created by wz on 17/3/23.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^VideoCacheStartAll)(void);
@interface VideoCacheController : UIViewController

@property (nonatomic, copy) VideoCacheStartAll startAllBlk;

@end
