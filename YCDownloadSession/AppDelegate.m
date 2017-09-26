//
//  AppDelegate.m
//  YCDownloadSession
//
//  Created by wz on 17/3/14.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "AppDelegate.h"
#import "MainTableViewController.h"
#import "YCDownloadSession.h"

@interface AppDelegate ()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSInteger duration;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    NSLog(@"%@", NSHomeDirectory());
    
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
    
    return YES;
}


- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSLog(@"%s", __func__);
}


-(void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler{
    NSLog(@"%s", __func__);
    [[YCDownloadSession downloadSession] addCompletionHandler:completionHandler identifier:identifier];
}


#pragma mark - test code
- (void)applicationWillResignActive:(UIApplication *)application{
    
    [self testTimer];
    NSLog(@"%s",__func__);
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self.timer invalidate];
    self.timer = nil;
    self.duration = 0;
    NSLog(@"%s", __func__);
}


- (void)testTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerRun) userInfo:nil repeats:true];
    [self.timer fire];
}

- (void)timerRun {
    _duration += 1;
    NSLog(@"%zd", _duration);
}


@end
