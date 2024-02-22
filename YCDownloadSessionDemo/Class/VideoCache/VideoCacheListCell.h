//
//  VideoCacheListCell.h
//  YCDownloadSession
//
//  Created by wz on 17/3/23.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VideoCacheListCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *speedLbl;


+(instancetype)videoCacheListCellWithTableView:(UITableView *)tableView;

+ (CGFloat)rowHeight;

@end
