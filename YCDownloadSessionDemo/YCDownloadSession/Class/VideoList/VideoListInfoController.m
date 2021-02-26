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
#import "AFNetworking.h"
#import "MJRefresh.h"
#import <YCDownloadSession/YCDownloadSession.h>

static NSInteger const pageSize = 10;

@interface VideoListInfoController ()<VideoListInfoCellDelegate>

@property (nonatomic, strong) NSMutableArray *videoListArr;
@property (nonatomic, assign) NSInteger page;

@end

@implementation VideoListInfoController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"视频列表";
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"缓存" style:UIBarButtonItemStylePlain target:self action:@selector(goCache)];
    _videoListArr = [NSMutableArray array];
    [self setupRefresh];
    [self.tableView.mj_header beginRefreshing];
}

- (void)setupRefresh{
    self.tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingTarget:self refreshingAction:@selector(reloadData)];
    self.tableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingTarget:self refreshingAction:@selector(loadMoreData)];
}

- (void)reloadData{
    [self.tableView.mj_footer resetNoMoreData];
    self.page = 0;
    [self getVideoList:false];
}

- (void)loadMoreData {
    self.page++;
    [self getVideoList: true];
}

- (void)getVideoList:(BOOL)isLoadMore {
    
    [[AFHTTPSessionManager manager] GET:@"http://api.onezen.cc/v1/video/list" parameters:@{@"page": @(self.page), @"size": @(pageSize)} progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSArray *res = [responseObject valueForKey:@"data"];
        if ([res isKindOfClass:[NSNull class]] || res.count==0) {
            [self.tableView.mj_footer endRefreshingWithNoMoreData];
            return ;
        }
        if (res.count>0) {
            if (!isLoadMore){
                [self.tableView.mj_header endRefreshing];
                [self.videoListArr removeAllObjects];
            }else{
                (res.count < pageSize) ? [self.tableView.mj_footer endRefreshingWithNoMoreData] : [self.tableView.mj_footer endRefreshing];
            }
            NSMutableArray *models = [VideoListInfoModel getVideoListInfo:res];
            [self.videoListArr addObjectsFromArray:models];
            [self.tableView reloadData];
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (error) {
            NSLog(@"%@",error);
        }
        [self getLocalVideoList];
    }];
}

- (void)downloadAll {
    [_videoListArr enumerateObjectsUsingBlock:^(VideoListInfoModel* model, NSUInteger idx, BOOL * _Nonnull stop) {
        YCDownloadItem *item = nil;
        if (model.vid) {
            item = [YCDownloadManager itemWithFileId:model.vid];
        }else if (model.video_url){
            item = [YCDownloadManager itemsWithDownloadUrl:model.video_url].firstObject;
        }
        if (!item) {
            item = [YCDownloadItem itemWithUrl:model.video_url fileId:model.vid];
            item.extraData = [VideoListInfoModel dateWithInfoModel:model];
            [YCDownloadManager startDownloadWithItem:item];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

- (void)getLocalVideoList {
    [self.videoListArr removeAllObjects];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"video.json" ofType:nil];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSArray *arrM = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSMutableArray *models = [VideoListInfoModel getVideoListInfo:arrM];
    [self.videoListArr addObjectsFromArray:models];
    [self.tableView reloadData];
    [self.tableView.mj_header endRefreshing];
    [self.tableView.mj_footer endRefreshingWithNoMoreData];
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
    if (model.vid) {
        item = [YCDownloadManager itemWithFileId:model.vid];
    }else if (model.video_url){
        item = [YCDownloadManager itemsWithDownloadUrl:model.video_url].firstObject;
    }
    if (!item) {
        item = [YCDownloadItem itemWithUrl:model.video_url fileId:model.vid];
        item.extraData = [VideoListInfoModel dateWithInfoModel:model];
        item.enableSpeed = true;
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
    if (model.vid) {
        item = [YCDownloadManager itemWithFileId:model.vid];
    }else if (model.video_url){
        item = [YCDownloadManager itemsWithDownloadUrl:model.video_url].firstObject;
    }
    [cell setDownloadStatus:item.downloadStatus];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [VideoListInfoCell rowHeight];
}

@end
