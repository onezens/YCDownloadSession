//
//  AppDelegate.m
//  YCDownloadSession
//
//  Created by wz on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "AppDelegate.h"
#import "MainTableViewController.h"
#import <Bugly/Bugly.h>
#import "YCDownloadSession.h"
#import "VideoListInfoModel.h"
#import "YCDownloadSwift.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    //root vc
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    MainTableViewController *vc = [[MainTableViewController alloc] init];
    UIViewController *rootVc = [[UINavigationController alloc] initWithRootViewController:vc];
    self.window.rootViewController = rootVc;
    [self.window makeKeyAndVisible];
    
    //注册通知
    if ([[UIDevice currentDevice].systemVersion doubleValue] >= 8.0) {
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil];
        [application registerUserNotificationSettings:settings];
    }
    
    //setup bugly
    [self setUpBugly];
    
    //setup downloadsession
    [self setUpDownload];
    
    [self testSwift];
    
    return YES;
}

- (void)setUpDownload {
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject;
    path = [path stringByAppendingPathComponent:@"download"];
    YCDConfig *config = [YCDConfig new];
    config.saveRootPath = path;
    config.uid = @"100006";
    config.maxTaskCount = 3;
    config.taskCachekMode = YCDownloadTaskCacheModeKeep;
    config.launchAutoResumeDownload = true;
    [YCDownloadManager mgrWithConfig:config];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadTaskFinishedNoti:) name:kDownloadTaskFinishedNoti object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(downloadAllTaskFinished) name:kDownloadTaskAllFinishedNoti object:nil];
}

- (void)setUpBugly {
    BuglyConfig *config = [BuglyConfig new];
    config.blockMonitorEnable = true;
    config.channel = @"git";
    config.unexpectedTerminatingDetectionEnable = true;
    config.symbolicateInProcessEnable =  true;
    [Bugly startWithAppId:@"900036376" config:config];
}

- (void)testSwift {
    TestSwiftController *testVc = [TestSwiftController new];
    testVc.title = @"test";
    [testVc logInfo];
}

#pragma mark notificaton

- (void)downloadAllTaskFinished{
    [self localPushWithTitle:@"YCDownloadSession" detail:@"所有的下载任务已完成！"];
}

- (void)downloadTaskFinishedNoti:(NSNotification *)noti{
    YCDownloadItem *item = noti.object;
    if (item) {
        VideoListInfoModel *mo = [VideoListInfoModel infoWithData:item.extraData];
        NSString *detail = [NSString stringWithFormat:@"%@ 视频，已经下载完成！", mo.title];
        [self localPushWithTitle:@"YCDownloadSession" detail:detail];
    }
}

#pragma mark local push

- (void)localPushWithTitle:(NSString *)title detail:(NSString *)body  {
    
    if (title.length == 0) return;
    UILocalNotification *localNote = [[UILocalNotification alloc] init];
    localNote.fireDate = [NSDate dateWithTimeIntervalSinceNow:3.0];
    localNote.alertBody = body;
    localNote.alertAction = @"滑动来解锁";
    localNote.hasAction = NO;
    localNote.soundName = @"default";
    localNote.userInfo = @{@"type" : @1};
    [[UIApplication sharedApplication] scheduleLocalNotification:localNote];
}


-(void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler{
    [[YCDownloader downloader] addCompletionHandler:completionHandler identifier:identifier];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"%s", __func__);
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"%s", __func__);
}

@end
