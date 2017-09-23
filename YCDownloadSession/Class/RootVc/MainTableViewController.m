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
#import "YCDownloadManager.h"

@interface MainTableViewController ()

@property (nonatomic, strong) UISwitch *cellarSwitch;

@end

@implementation MainTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"后台视频下载";
}

- (void)cellarSwitch:(UISwitch *)sender {
    
    [YCDownloadManager allowsCellularAccess:sender.isOn];
}

#pragma mark - tableView datasource & delegate


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellID = @"MainTableViewControllerCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"单个视频下载";
        cell.accessoryView = nil;
    }else if (indexPath.row == 1){
        cell.textLabel.text = @"多视频下载";
        cell.accessoryView = nil;
    }else{
        cell.textLabel.text = @"是否允许4G下载";
        cell.accessoryView = self.cellarSwitch;
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 3;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    
    if (indexPath.row == 0) {
        DownloadViewController *vc = [[DownloadViewController alloc] init];
        [self.navigationController pushViewController:vc animated:true];
        return;
    }else if (indexPath.row == 1){
        VideoListInfoController *vc = [[VideoListInfoController alloc] init];
        [self.navigationController pushViewController:vc animated:true];
    }
}


#pragma mark - lazy loading

- (UISwitch *)cellarSwitch {
    
    if (!_cellarSwitch) {
        _cellarSwitch = [[UISwitch alloc] init];
        [_cellarSwitch setOn:[YCDownloadManager isAllowsCellularAccess]];
        [_cellarSwitch addTarget:self action:@selector(cellarSwitch:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cellarSwitch;
}


@end
