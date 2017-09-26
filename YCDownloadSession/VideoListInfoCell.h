//
//  VideoListInfoCell.h
//  YCDownloadSession
//
//  Created by wz on 17/3/23.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "VideoListInfoModel.h"
#import "YCDownloadItem.h"
@class VideoListInfoCell;

@protocol VideoListInfoCellDelegate <NSObject>

- (void)videoListCell:(VideoListInfoCell *)cell downloadVideo:(VideoListInfoModel *)model;

@end

@interface VideoListInfoCell : UITableViewCell
@property (nonatomic, strong) VideoListInfoModel *videoModel;
@property (nonatomic, weak) id <VideoListInfoCellDelegate> delegate;
+ (instancetype)videoListInfoCellWithTableView:(UITableView *)tableView;
+ (CGFloat)rowHeight;
- (void)setDownloadStatus:(YCDownloadStatus)status;
@end
