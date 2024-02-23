//
//  ViewController.m
//  YCDownloadSession
//
//  Created by wz on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "DownloadViewController.h"
#import <YCDownloadSession/YCDownloadSession.h>

static NSString * const kDownloadTaskIdKey = @"kDownloadTaskIdKey";
@interface DownloadViewController ()

@property (nonatomic, copy) NSString *downloadURL;
@property (nonatomic, weak) UILabel *progressLbl;

@property (nonatomic, strong) YCDownloadTask *task;

@property (nonatomic, strong) NSData *resumeData;


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
    
    
    UIButton *pauseBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 150, 100, 36)];
    [pauseBtn setTitle:@"pause" forState:UIControlStateNormal];
    [pauseBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [pauseBtn addTarget:self action:@selector(pause) forControlEvents:UIControlEventTouchUpInside];
    [pauseBtn setTitleColor:[UIColor cyanColor] forState:UIControlStateHighlighted];
    [self.view addSubview:pauseBtn];
    
    UIButton *resumeBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 200, 100, 36)];
    [resumeBtn setTitle:@"resume" forState:UIControlStateNormal];
    [resumeBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [resumeBtn setTitleColor:[UIColor cyanColor] forState:UIControlStateHighlighted];
    [resumeBtn addTarget:self action:@selector(resume) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:resumeBtn];
    
    UIButton *stopBtn = [[UIButton alloc] initWithFrame:CGRectMake(100, 250, 100, 36)];
    [stopBtn setTitle:@"stop" forState:UIControlStateNormal];
    [stopBtn setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [stopBtn addTarget:self action:@selector(stop) forControlEvents:UIControlEventTouchUpInside];
    [stopBtn setTitleColor:[UIColor cyanColor] forState:UIControlStateHighlighted];
    [self.view addSubview:stopBtn];
    
    self.downloadURL = @"http://dldir1.qq.com/qqfile/QQforMac/QQ_V6.0.1.dmg";
    
    UILabel *lbl = [[UILabel alloc] init];
    lbl.text = @"0%";
    lbl.frame = CGRectMake(100, 300, 200, 30);
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.textColor = [UIColor blackColor];
    self.progressLbl = lbl;
    [self.view addSubview:lbl];
    
    __weak typeof(self) weakSelf = self;
    
    YCDownloadSession *session = [YCDownloadSession sharedSession];
    self.task = [session taskWithUrlStr:self.downloadURL];
    self.task.progressBlock = ^(float progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            lbl.text = @(progress).stringValue;
        });
        NSLog(@"[YCDownload] progress: %f", progress);
    };
    self.task.completionBlock = ^(NSURL * _Nonnull fileURL, NSError * _Nonnull error) {
        NSLog(@"[YCDownload] completion path: %@ error: %@", fileURL, error);
    };

}

- (void)start {
    [self.task resume];
}

- (void)resume {
    [self.task resumeWithResumeData:self.resumeData];
}

- (void)pause {
    [self.task pauseWithResumeData:^(NSData * _Nullable resumeData) {
        self.resumeData = resumeData;
    }];
}

- (void)stop {
  
}


@end
