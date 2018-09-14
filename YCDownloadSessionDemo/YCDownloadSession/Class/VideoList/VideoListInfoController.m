//
//  VideoListInfoController.m
//  YCDownloadSession
//
//  Created by wz on 17/3/23.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "VideoListInfoController.h"
#import "VideoListInfoCell.h"
#import "VideoListInfoModel.h"
#import "VideoCacheController.h"
#import "YCDownloadManager.h"

@interface VideoListInfoController ()<VideoListInfoCellDelegate>

@property (nonatomic, strong) NSMutableArray *videoListArr;

@end

@implementation VideoListInfoController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"视频列表";
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self getVideoList];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"缓存" style:UIBarButtonItemStylePlain target:self action:@selector(goCache)];
//    [self downloadAll];
}

- (void)downloadAll {
    [_videoListArr enumerateObjectsUsingBlock:^(VideoListInfoModel* model, NSUInteger idx, BOOL * _Nonnull stop) {
        YCDownloadItem *item = nil;
        if (model.file_id) {
            item = [YCDownloadManager itemWithFileId:model.file_id];
        }else if (model.mp4_url){
            item = [YCDownloadManager itemsWithDownloadUrl:model.mp4_url].firstObject;
        }
        if (!item) {
            item = [YCDownloadItem itemWithUrl:model.mp4_url fileId:model.file_id];
            item.extraData = [VideoListInfoModel dateWithInfoModel:model];
            [YCDownloadManager startDownloadWithItem:item];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)getVideoList {
    
    NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"video.json" ofType:nil];
    NSData *videoData = [[NSData alloc] initWithContentsOfFile:dataPath];
    NSArray *videoArr = [NSJSONSerialization JSONObjectWithData:videoData options:0 error:nil];
    _videoListArr = [VideoListInfoModel getVideoListInfo:videoArr];
    [self.tableView reloadData];
}


- (void)goCache {
    VideoCacheController *vc = [[VideoCacheController alloc] init];
    vc.startAllBlk = ^{
        [self downloadAll];
    };
    [self.navigationController pushViewController:vc animated:true];
}
#pragma mark - videolistcell delegate


/**
 点击下载
 */
- (void)videoListCell:(VideoListInfoCell *)cell downloadVideo:(VideoListInfoModel *)model {
    YCDownloadItem *item = nil;
    if (model.file_id) {
        item = [YCDownloadManager itemWithFileId:model.file_id];
    }else if (model.mp4_url){
        item = [YCDownloadManager itemsWithDownloadUrl:model.mp4_url].firstObject;
    }
    if (!item) {
        item = [YCDownloadItem itemWithUrl:model.mp4_url fileId:model.file_id];
        item.extraData = [VideoListInfoModel dateWithInfoModel:model];
        [YCDownloadManager startDownloadWithItem:item];
    }
    VideoCacheController *vc = [[VideoCacheController alloc] init];
    [self.navigationController pushViewController:vc animated:true];
}

#pragma mark - Table view data source & delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

    return self.videoListArr.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoListInfoCell *cell = [VideoListInfoCell videoListInfoCellWithTableView:tableView];
    VideoListInfoModel *model = self.videoListArr[indexPath.row];
    [cell setVideoModel:model];
    cell.delegate = self;
    YCDownloadItem *item = nil;
    if (model.file_id) {
        item = [YCDownloadManager itemWithFileId:model.file_id];
    }else if (model.mp4_url){
        item = [YCDownloadManager itemsWithDownloadUrl:model.mp4_url].firstObject;
    }
    [cell setDownloadStatus:item.downloadStatus];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [VideoListInfoCell rowHeight];
}

@end
