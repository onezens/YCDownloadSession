//
//  VideoCacheController.m
//  YCDownloadSession
//
//  Created by wangzhen on 17/3/23.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "VideoCacheController.h"
#import "VideoCacheListCell.h"

@interface VideoCacheController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation VideoCacheController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupTableView];
    self.title = @"缓存";
    self.view.backgroundColor = [UIColor whiteColor];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    VideoCacheListCell *cell = [VideoCacheListCell videoCacheListCellWithTableView:tableView];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 20;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [VideoCacheListCell rowHeight];
}


@end
