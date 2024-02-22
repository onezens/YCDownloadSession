//
//  VideoCacheController.m
//  YCDownloadSession
//
//  Created by wz on 17/3/23.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "VideoCacheController.h"
#import "VideoCacheListCell.h"
#import "PlayerViewController.h"

static NSString * const kDefinePauseAllTitle = @"暂停所有";
static NSString * const kDefineStartAllTitle = @"开始所有";

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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:self.cacheVideoList.count > 0 ?  kDefinePauseAllTitle : kDefineStartAllTitle  style:UIBarButtonItemStyleDone target:self action:@selector(pauseAll)];
}

- (void)getCacheVideoList {
    
    [self.cacheVideoList removeAllObjects];
    [self.tableView reloadData];
    self.navigationItem.rightBarButtonItem.enabled = self.cacheVideoList.count>0;
}

- (void)setupTableView {
    _tableView = [[UITableView alloc] init];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.frame = self.view.bounds;
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:_tableView];
}

- (void)pauseAll {
    if (self.navigationItem.rightBarButtonItem.title == kDefinePauseAllTitle) {
        self.navigationItem.rightBarButtonItem.title = kDefineStartAllTitle;
    }else{
        if (self.startAllBlk && self.cacheVideoList.count==0) {
            self.startAllBlk();
            [self getCacheVideoList];
        }else{
            self.navigationItem.rightBarButtonItem.title = kDefinePauseAllTitle;
        }
    }
}

#pragma mark - uitableview datasource & delegate

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        
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

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cacheVideoList.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [VideoCacheListCell rowHeight];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
 
}


@end
