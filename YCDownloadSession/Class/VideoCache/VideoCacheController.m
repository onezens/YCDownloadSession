//
//  VideoCacheController.m
//  YCDownloadSession
//
//  Created by wz on 17/3/23.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "VideoCacheController.h"
#import "VideoCacheListCell.h"
#import "YCDownloadManager.h"
#import "PlayerViewController.h"

@interface VideoCacheController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *cacheVideoList;

@end

@implementation VideoCacheController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupTableView];
    self.title = @"缓存";
    self.view.backgroundColor = [UIColor whiteColor];
    self.cacheVideoList = [NSMutableArray array];
    [self getCacheVideoList];
    [YCDownloadManager setMaxTaskCount:3];
    [YCDownloadManager localPushOn:true];
}

- (void)getCacheVideoList {
    
    [self.cacheVideoList removeAllObjects];
    [self.cacheVideoList addObjectsFromArray:[YCDownloadManager downloadList]];
    [self.cacheVideoList addObjectsFromArray:[YCDownloadManager finishList]];
    [self.tableView reloadData];
}

- (void)setupTableView {
    _tableView = [[UITableView alloc] init];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.frame = self.view.bounds;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_tableView];
}

#pragma mark - uitableview datasource & delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        YCDownloadItem *item = _cacheVideoList[indexPath.row];
        [YCDownloadManager stopDownloadWithId:item.fileId];
        
        [self.cacheVideoList removeObjectAtIndex:indexPath.row];
        // Delete the row from the data source.
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        
    }
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    VideoCacheListCell *cell = [VideoCacheListCell videoCacheListCellWithTableView:tableView];
    YCDownloadItem *item = self.cacheVideoList[indexPath.row];
    cell.item = item;
    item.delegate = cell;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cacheVideoList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [VideoCacheListCell rowHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    YCDownloadItem *item = self.cacheVideoList[indexPath.row];
    if (item.downloadStatus == YCDownloadStatusDownloading) {
        [YCDownloadManager pauseDownloadWithId:item.downloadUrl];
    }else if (item.downloadStatus == YCDownloadStatusPaused){
        [YCDownloadManager resumeDownloadWithId:item.downloadUrl];
    }else if (item.downloadStatus == YCDownloadStatusFailed){
        [YCDownloadManager resumeDownloadWithId:item.downloadUrl];
    }else if (item.downloadStatus == YCDownloadStatusWaiting){
        [YCDownloadManager pauseDownloadWithId:item.downloadUrl];
    }else if (item.downloadStatus == YCDownloadStatusFinished){
        PlayerViewController *playerVC = [[PlayerViewController alloc] init];
        playerVC.playerItem = item;
        [self.navigationController pushViewController:playerVC animated:true];
    }
    [self.tableView reloadData];
}


@end
