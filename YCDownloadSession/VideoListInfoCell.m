//
//  VideoListInfoCell.m
//  YCDownloadSession
//
//  Created by wz on 17/3/23.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "VideoListInfoCell.h"
#import "UIImageView+WebCache.h"

@interface VideoListInfoCell()

@property (weak, nonatomic) IBOutlet UIImageView *coverImgView;
@property (weak, nonatomic) IBOutlet UILabel *titleLbl;
@property (weak, nonatomic) IBOutlet UILabel *timeLbl;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;


@end

@implementation VideoListInfoCell

+ (instancetype)videoListInfoCellWithTableView:(UITableView *)tableView {
    static NSString *cellId = @"VideoListInfoCell";
    VideoListInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        cell = [[NSBundle mainBundle] loadNibNamed:@"VideoListInfoCell" owner:self options:nil].firstObject;
        
    }
    return cell;
}

+ (CGFloat)rowHeight {
    return 84.0f;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.downloadBtn.layer.cornerRadius = 4.0f;
    self.downloadBtn.layer.masksToBounds = true;
    self.coverImgView.layer.cornerRadius = 6;
    self.coverImgView.layer.masksToBounds = true;
    
}

- (void)setVideoModel:(VideoListInfoModel *)videoModel {
    _videoModel = videoModel;
    self.titleLbl.text = videoModel.title;
    self.timeLbl.text = videoModel.videosource;
    [self.coverImgView sd_setImageWithURL:[NSURL URLWithString:videoModel.cover]];
}

- (void)setIsDownload:(BOOL)isDownload {
    
    _isDownload = isDownload;
    if (isDownload) {
        [self.downloadBtn setTitle:@"已下载" forState:UIControlStateNormal];
    }else{
        [self.downloadBtn setTitle:@"下载" forState:UIControlStateNormal];
    }
}


- (IBAction)downloadBtnClick:(id)sender {
    if ([self.delegate respondsToSelector:@selector(videoListCell:downloadVideo:)]) {
        [self.delegate videoListCell:self downloadVideo:self.videoModel];
    }
}

@end
