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
#import "YCDownloadSession.h"

@interface MainTableViewController ()

@property (nonatomic, strong) UISwitch *cellarSwitch;

@end

@implementation MainTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"后台视频下载";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView reloadData];
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
    }
    
    
    if (indexPath.row == 0) {
        cell.textLabel.text = @"单个文件下载";
        cell.accessoryView = nil;
    }else if (indexPath.row == 1){
        cell.textLabel.text = @"多视频下载";
        cell.accessoryView = nil;
    }else if(indexPath.row==2){
        cell.textLabel.text = @"是否允许4G下载";
        cell.accessoryView = self.cellarSwitch;
    }else if (indexPath.row==3){
        cell.textLabel.text = @"磁盘剩余空间";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [YCDownloadUtils fileSizeStringFromBytes:[YCDownloadUtils fileSystemFreeSize]]];
    }else if (indexPath.row==4){
        cell.textLabel.text = @"当前缓存大小";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [YCDownloadUtils fileSizeStringFromBytes:[YCDownloadManager videoCacheSize]]];
    }else if (indexPath.row==5){
        cell.textLabel.text = @"清空所有视频缓存";
    }
    
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return 6;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.row == 0) {
        DownloadViewController *vc = [[DownloadViewController alloc] init];
        [self.navigationController pushViewController:vc animated:true];
        return;
    }else if (indexPath.row == 1){
        VideoListInfoController *vc = [[VideoListInfoController alloc] init];
        [self.navigationController pushViewController:vc animated:true];
    }else if (indexPath.row==5){
        
        UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"是否清空所有下载文件缓存？" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            //注意清空缓存的逻辑,YCDownloadSession单独下载的文件单独清理，这里的大小由YCDownloadManager控制
            [YCDownloadManager removeAllCache];
            [self.tableView reloadData];
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
        [alertVc addAction:confirm];
        [alertVc addAction:cancel];
        [self presentViewController:alertVc animated:true completion:nil];
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
