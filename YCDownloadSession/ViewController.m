//
//  ViewController.m
//  YCDownloadSession
//
//  Created by wangzhen on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "ViewController.h"
#import "YCDownloadSession.h"

@interface ViewController ()<YCDownloadSessionDelegate>

@property (nonatomic, copy) NSString *downloadURL;
@property (nonatomic, weak) UILabel *progressLbl;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(100, 100, 100, 36)];
    [btn setTitle:@"start" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    UIButton *resumeBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 150, 100, 36)];
    [resumeBtn setTitle:@"resume" forState:UIControlStateNormal];
    [resumeBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [resumeBtn addTarget:self action:@selector(resume) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:resumeBtn];
    
    UIButton *stopBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 200, 100, 36)];
    [stopBtn setTitle:@"stop" forState:UIControlStateNormal];
    [stopBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [stopBtn addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stopBtn];
    
    UIButton *pauseBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 250, 100, 36)];
    [pauseBtn setTitle:@"pause" forState:UIControlStateNormal];
    [pauseBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [pauseBtn addTarget:self action:@selector(pause) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:pauseBtn];

    // http://src.onezen.cc/123.mov
    // http://flv2.bn.netease.com/videolib3/1706/07/gDNOH8458/SD/gDNOH8458-mobile.mp4
    self.downloadURL = @"https://flv2.bn.netease.com/videolib3/1706/07/gDNOH8458/SD/gDNOH8458-mobile.mp4";
    
    UILabel *lbl = [[UILabel alloc] init];
    lbl.text = @"0%";
    lbl.frame = CGRectMake(100, 300, 200, 30);
    lbl.textAlignment = NSTextAlignmentCenter;
    self.progressLbl = lbl;
    [self.view addSubview:lbl];
    
}

- (void)downloadProgress:(YCDownloadTask *)downloadItem totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    self.progressLbl.text = [NSString stringWithFormat:@"%f",(float)totalBytesWritten / totalBytesExpectedToWrite * 100];
}

- (void)downloadFailed:(YCDownloadTask *)downloadItem {
    
    self.progressLbl.text = @"download failed!";
}

- (void)downloadinished:(YCDownloadTask *)downloadItem {
    self.progressLbl.text = @"download success!";
}

- (void)start {
    [[YCDownloadSession downloadSession] startDownloadWithUrl:self.downloadURL delegate:self];
}
- (void)resume {
    [[YCDownloadSession downloadSession] resumeDownloadWithUrl:self.downloadURL delegate:self];
}

- (void)pause {
    [[YCDownloadSession downloadSession] pauseDownloadWithUrl:self.downloadURL];
}

- (void)stop {
    [[YCDownloadSession downloadSession] stopDownloadWithUrl:self.downloadURL];
}


@end
