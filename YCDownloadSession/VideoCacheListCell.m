//
//  VideoCacheListCell.m
//  YCDownloadSession
//
//  Created by wz on 17/3/23.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "VideoCacheListCell.h"
#import "UIImageView+WebCache.h"
#import "YCDownloadManager.h"

@interface VideoCacheListCell ()

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *titleLbl;
@property (weak, nonatomic) IBOutlet UILabel *sizeLbl;
@property (weak, nonatomic) IBOutlet UILabel *statusLbl;
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
    [self changeSizeLblDownloadedSize:item.downloadedSize totalSize:item.fileSize];
    [self setDownloadStatus:item.downloadStatus];
}


- (void)setDownloadStatus:(YCDownloadStatus)status {

    switch (status) {
        case YCDownloadStatusWaiting:
            self.statusLbl.text = @"正在等待";
            break;
        case YCDownloadStatusDownloading:
            self.statusLbl.text = @"正在下载";
            break;
        case YCDownloadStatusPaused:
            self.statusLbl.text = @"暂停下载";
            break;
        case YCDownloadStatusFinished:
            self.statusLbl.text = @"下载成功";
            NSLog(@"%@", [_item savePath]);
            self.progressView.progress = 1;
            break;
        case YCDownloadStatusFailed:
            self.statusLbl.text = @"下载失败";
            break;
            
        default:
            break;
    }
}



- (void)changeSizeLblDownloadedSize:(int64_t)downloadedSize totalSize:(int64_t)totalSize {

    self.sizeLbl.text = [NSString stringWithFormat:@"%@ / %@",[YCDownloadManager fileSizeStringFromBytes:downloadedSize], [YCDownloadManager fileSizeStringFromBytes:totalSize]];
    
    float progress = 0;
    if (totalSize != 0) {
        progress = (float)downloadedSize / totalSize;
    }
    self.progressView.progress = progress;
}

- (void)downloadItemStatusChanged:(YCDownloadItem *)item {
   [self setDownloadStatus:item.downloadStatus];
}

- (void)downloadItem:(YCDownloadItem *)item downloadedSize:(int64_t)downloadedSize totalSize:(int64_t)totalSize {
    
    [self changeSizeLblDownloadedSize:downloadedSize totalSize:totalSize];
}




@end
