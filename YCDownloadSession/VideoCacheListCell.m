//
//  VideoCacheListCell.m
//  YCDownloadSession
//
//  Created by wangzhen on 17/3/23.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "VideoCacheListCell.h"
#import "UIImageView+WebCache.h"

@interface VideoCacheListCell ()

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *titleLbl;
@property (weak, nonatomic) IBOutlet UILabel *sizeLbl;
@property (weak, nonatomic) IBOutlet UILabel *statusAndSpeedLbl;
@property (weak, nonatomic) IBOutlet UIImageView *coverImgView;


@end


@implementation VideoCacheListCell

+ (instancetype)videoCacheListCellWithTableView:(UITableView *)tableView {
    static NSString *cellId = @"VideoCacheListCell";
    VideoCacheListCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[NSBundle mainBundle] loadNibNamed:@"VideoCacheListCell" owner:nil options:nil].firstObject;
    }
    return cell;
    
}

+ (CGFloat)rowHeight {
    return 84.0f;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.coverImgView.layer.cornerRadius = 6.0f;
    self.coverImgView.layer.masksToBounds = true;
}

- (void)setItem:(YCDownloadItem *)item {
    
    _item = item;
    self.titleLbl.text = item.fileName;
    [self.coverImgView sd_setImageWithURL:[NSURL URLWithString:item.thumbImageUrl]];
    [self changeSizeLblDownloadedSize:item.fileSize totalSize:item.fileSize];
}


- (void)changeSizeLblDownloadedSize:(NSInteger)downloadedSize totalSize:(NSInteger)totalSize {
    self.sizeLbl.text = [NSString stringWithFormat:@"%zd/%zd",downloadedSize, totalSize];
}


- (void)downloadItem:(YCDownloadItem *)item downloadedSize:(NSInteger)downloadedSize totalSize:(NSInteger)totalSize {
    self.progressView.progress = (float)downloadedSize / totalSize;
    [self changeSizeLblDownloadedSize:downloadedSize totalSize:totalSize];
}

@end
