//
//  VideoListInfoCell.h
//  YCDownloadSession
//
//  Created by wangzhen on 17/3/23.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoListInfoModel.h"

@interface VideoListInfoCell : UITableViewCell
@property (nonatomic, strong) VideoListInfoModel *videoModel;
+ (instancetype)videoListInfoCellWithTableView:(UITableView *)tableView;
+ (CGFloat)rowHeight;

@end
