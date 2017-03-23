//
//  VideoListInfoCell.m
//  YCDownloadSession
//
//  Created by wangzhen on 17/3/23.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "VideoListInfoCell.h"
#import "AFNetworking.h"

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
    
}

- (void)setVideoModel:(VideoListInfoModel *)videoModel {
    _videoModel = videoModel;
    self.titleLbl.text = videoModel.title;
    self.timeLbl.text = videoModel.ptime;
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:videoModel.mp4_url]];
    [manager downloadTaskWithRequest:req progress:nil destination:nil completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        self.coverImgView.image = [UIImage imageWithContentsOfFile:filePath.absoluteString];
    }];
}


- (IBAction)downloadBtnClick:(id)sender {
    
}

@end
