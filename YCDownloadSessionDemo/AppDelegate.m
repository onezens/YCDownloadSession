//
//  AppDelegate.m
//  YCDownloadSession
//
//  Created by wz on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "AppDelegate.h"
#import "MainTableViewController.h"
#import "VideoListInfoModel.h"
#import "YCDownloadSwift.h"
#import <YCDownloadSession/YCDownloadSession.h>

@interface AppDelegate ()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger duration;


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
    //setup downloadsession
    [self setUpDownload];
    
    [self testSwift];
    
    return YES;
}

- (void)setUpDownload
{
//    YCDownloadSessionConfig *conf = [YCDownloadSessionConfig new];
//    YCDownloadSession *session = [YCDownloadSession sessionWithConfiguration:conf];
//    [[session taskWithUrlStr:@"xxx"] start];
    
}

//- (void)setUpBugly {
//    BuglyConfig *config = [BuglyConfig new];
//    config.blockMonitorEnable = true;
//    config.channel = @"git";
//    config.unexpectedTerminatingDetectionEnable = true;
//    config.symbolicateInProcessEnable =  true;
//    [Bugly startWithAppId:@"900036376" config:config];
//}

- (void)testSwift {
//    TestSwiftController *testVc = [TestSwiftController new];
//    testVc.title = @"test";
//    [testVc logInfo];
}

#pragma mark notificaton

- (void)downloadTaskFinishedNoti:(NSNotification *)noti{
   
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


- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler{
    NSLog(@"Background event: %@", identifier);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        completionHandler();
    });
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self.timer invalidate];
    self.timer = nil;
    self.duration = 0;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    NSLog(@"%s", __func__);
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 repeats:true block:^(NSTimer * _Nonnull timer) {
        self.duration += 1;
        NSLog(@"timer run: %ld", (long)self.duration);
    }];
    [self.timer fire];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSLog(@"%s", __func__);
}

@end
