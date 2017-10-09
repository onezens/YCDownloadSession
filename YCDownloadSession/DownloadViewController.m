//
//  ViewController.m
//  YCDownloadSession
//
//  Created by wz on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "DownloadViewController.h"
#import "YCDownloadSession.h"

@interface DownloadViewController ()<YCDownloadTaskDelegate>

@property (nonatomic, copy) NSString *downloadURL;
@property (nonatomic, weak) UILabel *progressLbl;

@end

@implementation DownloadViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 36)];
    [btn setTitle:@"start" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor cyanColor] forState:UIControlStateHighlighted];
    [btn addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UIButton *resumeBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 150, 100, 36)];
    [resumeBtn setTitle:@"resume" forState:UIControlStateNormal];
    [resumeBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [resumeBtn setTitleColor:[UIColor cyanColor] forState:UIControlStateHighlighted];
    [resumeBtn addTarget:self action:@selector(resume) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:resumeBtn];
    
    UIButton *stopBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 200, 100, 36)];
    [stopBtn setTitle:@"stop" forState:UIControlStateNormal];
    [stopBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [stopBtn addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
    [stopBtn setTitleColor:[UIColor cyanColor] forState:UIControlStateHighlighted];
    [self.view addSubview:stopBtn];
    
    UIButton *pauseBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 250, 100, 36)];
    [pauseBtn setTitle:@"pause" forState:UIControlStateNormal];
    [pauseBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [pauseBtn addTarget:self action:@selector(pause) forControlEvents:UIControlEventTouchUpInside];
    [pauseBtn setTitleColor:[UIColor cyanColor] forState:UIControlStateHighlighted];
    [self.view addSubview:pauseBtn];

    self.downloadURL = @"http://dldir1.qq.com/qqfile/QQforMac/QQ_V6.0.1.dmg";
    
    UILabel *lbl = [[UILabel alloc] init];
    lbl.text = @"0%";
    lbl.frame = CGRectMake(100, 300, 200, 30);
    lbl.textAlignment = NSTextAlignmentCenter;
    self.progressLbl = lbl;
    [self.view addSubview:lbl];
    
}

- (void)downloadProgress:(YCDownloadTask *)task totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    self.progressLbl.text = [NSString stringWithFormat:@"%f",(float)totalBytesWritten / totalBytesExpectedToWrite * 100];
}

- (void)downloadFailed:(YCDownloadTask *)task {
    self.progressLbl.text = @"download failed!";
}

- (void)downloadinished:(YCDownloadTask *)task {
    self.progressLbl.text = @"download success!";
}

- (void)start {
    [[YCDownloadSession downloadSession] startDownloadWithUrl:self.downloadURL delegate:self saveName:nil];
}
- (void)resume {
    [[YCDownloadSession downloadSession] resumeDownloadWithUrl:self.downloadURL delegate:self saveName:nil];
}

- (void)pause {
    [[YCDownloadSession downloadSession] pauseDownloadWithUrl:self.downloadURL];
}

- (void)stop {
    [[YCDownloadSession downloadSession] stopDownloadWithUrl:self.downloadURL];
}


@end
