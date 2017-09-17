//
//  MainTableViewController.m
//  YCDownloadSession
//
//  Created by wz on 2017/9/17.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "MainTableViewController.h"
#import "DownloadViewController.h"
#import "VideoListInfoController.h"

@interface MainTableViewController ()

@end

@implementation MainTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"后台视频下载";
}

#pragma mark - tableView datasource & delegate


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellID = @"MainTableViewControllerCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    NSString *title = indexPath.row == 0 ? @"单个视频下载" : @"多视频下载";
    cell.textLabel.text = title;
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 2;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 0) {
        DownloadViewController *vc = [[DownloadViewController alloc] init];
        [self.navigationController pushViewController:vc animated:true];
        return;
    }
    
    VideoListInfoController *vc = [[VideoListInfoController alloc] init];
    [self.navigationController pushViewController:vc animated:true];
    
    
}


@end
