//
//  ViewController.m
//  YCDownloadSession
//
//  Created by wz on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "DownloadViewController.h"
#import "YCDownloadSession.h"
#import "YCDownloader.h"

static NSString * const kDownloadTaskIdKey = @"kDownloadTaskIdKey";
@interface DownloadViewController ()

@property (nonatomic, copy) NSString *downloadURL;
@property (nonatomic, weak) UILabel *progressLbl;
@property (nonatomic, weak) YCDownloadTask *downloadTask;

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
    [YCDownloader downloader];
}

- (void)downloadProgress:(YCDownloadTask *)task downloadedSize:(NSUInteger)downloadedSize fileSize:(NSUInteger)fileSize {
    self.progressLbl.text = [NSString stringWithFormat:@"%f",(float)downloadedSize / fileSize * 100];
}


- (void)downloadStatusChanged:(YCDownloadStatus)status downloadTask:(YCDownloadTask *)task {
    if (status == YCDownloadStatusFinished) {
        self.progressLbl.text = @"download success!";
    }else if (status == YCDownloadStatusFailed){
        self.progressLbl.text = @"download failed!";
    }
}

- (void)start {
     self.downloadTask = [[YCDownloader downloader] downloadWithUrl:self.downloadURL progress:^(NSProgress *progress) {
       self.progressLbl.text = [NSString stringWithFormat:@"%f",progress.fractionCompleted];
    } completion:^(NSString *localPath, NSError *error) {
        NSLog(@"%@", localPath);
    }];
    [[NSUserDefaults standardUserDefaults] setValue:self.downloadTask.taskId forKey:kDownloadTaskIdKey];
    
}
- (void)resume {
    if (self.downloadTask) {
        [[YCDownloader downloader] resumeDownloadTask:self.downloadTask];
    }else{
        //recovery download
        NSString *tid = [[NSUserDefaults standardUserDefaults] valueForKey:kDownloadTaskIdKey];
        self.downloadTask = [[YCDownloader downloader] resumeDownloadTaskWithTid:tid progress:^(NSProgress *progress) {
            self.progressLbl.text = [NSString stringWithFormat:@"%f",progress.fractionCompleted];
        } completion:^(NSString *localPath, NSError *error) {
            NSLog(@"%@", localPath);
        }];
    }
}

- (void)pause {
    [[YCDownloader downloader] pauseDownloadTask:self.downloadTask];
}

- (void)stop {
    [[YCDownloader downloader] cancelDownloadTask:self.downloadTask];
}


@end
