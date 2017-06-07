//
//  VideoListInfoController.m
//  YCDownloadSession
//
//  Created by wangzhen on 17/3/23.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "VideoListInfoController.h"
#import "VideoListInfoCell.h"
#import "VideoListInfoModel.h"
#import "AFNetworking.h"
#import "VideoCacheController.h"

@interface VideoListInfoController ()<VideoListInfoCellDelegate>

@property (nonatomic, strong) NSArray *videoListArr;

@end

@implementation VideoListInfoController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"网易视频";
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self getVideoList];
}

- (void)getVideoList {
    
    NSString *dataPath = [[NSBundle mainBundle] pathForResource:@"video.json" ofType:nil];
    NSData *videoData = [[NSData alloc] initWithContentsOfFile:dataPath];
    NSArray *videoArr = [NSJSONSerialization JSONObjectWithData:videoData options:0 error:nil];
    _videoListArr = [VideoListInfoModel getVideoListInfo:videoArr];;
    [self.tableView reloadData];
}

- (void)videoListCell:(VideoListInfoCell *)cell downloadVideo:(VideoListInfoModel *)model {
    NSLog(@"%@", model.mp4_url);
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
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [VideoListInfoCell rowHeight];
}

@end
