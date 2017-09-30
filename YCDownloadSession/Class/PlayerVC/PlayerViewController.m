//
//  PlayerViewController.m
//  YCDownloadSession
//
//  Created by wz on 2017/9/30.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "PlayerViewController.h"
#import "WMPlayer.h"

@interface PlayerViewController ()<WMPlayerDelegate>

@property (nonatomic, strong) WMPlayer *player;
@property (nonatomic, assign) CGRect originalFrame;
@property (nonatomic, assign) BOOL isFullScreen;

@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = self.playerItem.fileName;
    self.originalFrame = CGRectMake(0, 64, self.view.bounds.size.width, 200);
    
    self.player = [[WMPlayer alloc] init];
    self.player.delegate = self;
    [self.view addSubview:_player];
    //保存路径需要转换为url路径，才能播放
    NSURL *url = [NSURL fileURLWithPath:self.playerItem.savePath];
    [self.player setURLString:url.absoluteString];
    [_player play];
}

- (void)dealloc {
    [_player pause];
    [_player removeFromSuperview];
}


#pragma mark rotate

/**
 *  旋转屏幕的时候，是否自动旋转子视图，NO的话不会旋转控制器的子控件
 *
 */
- (BOOL)shouldAutorotate
{
    return true;
}

/**
 *  当前控制器支持的旋转方向
 */
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscapeRight | UIInterfaceOrientationMaskLandscapeLeft  ;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if (self.player.isFullscreen)
        return UIInterfaceOrientationPortrait;
    return UIInterfaceOrientationLandscapeRight ;
}

/**
 需要切换的屏幕方向，手动转屏
 */
- (void)setFullScreen:(BOOL)isFullScreen {
    
    if (isFullScreen) {
        [self rotateOrientation:UIInterfaceOrientationLandscapeRight];
    }else{
        [self rotateOrientation:UIInterfaceOrientationPortrait];
    }
}

- (void)rotateOrientation:(UIInterfaceOrientation)orientation {
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:YES];
    [[UIDevice currentDevice] setValue:[NSNumber numberWithInteger:orientation] forKey:@"orientation"];
}

//自动转屏或者手动调用
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    self.isFullScreen = size.width > size.height;
}


- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (self.isFullScreen){
            
        [self.navigationController setNavigationBarHidden:true];
        self.player.frame = self.view.bounds;
        self.player.isFullscreen = true;
    }else{
        [self.navigationController setNavigationBarHidden:false];
        self.player.frame = self.originalFrame;
        self.player.isFullscreen = false;
    }
}

#pragma mark - player view delegate


//点击播放暂停按钮代理方法
-(void)wmplayer:(WMPlayer *)wmplayer clickedPlayOrPauseButton:(UIButton *)playOrPauseBtn{
    NSLog(@"%s", __func__);
}
//点击关闭按钮代理方法
-(void)wmplayer:(WMPlayer *)wmplayer clickedCloseButton:(UIButton *)closeBtn{
    
    if (self.player.isFullscreen) {
        [self setFullScreen:false];
    }else{
        [self.navigationController popViewControllerAnimated:true];
    }
}
//点击全屏按钮代理方法
-(void)wmplayer:(WMPlayer *)wmplayer clickedFullScreenButton:(UIButton *)fullScreenBtn{
    [self setFullScreen:!self.player.isFullscreen];
}
//单击WMPlayer的代理方法
-(void)wmplayer:(WMPlayer *)wmplayer singleTaped:(UITapGestureRecognizer *)singleTap{
    NSLog(@"%s", __func__);
}
//双击WMPlayer的代理方法
-(void)wmplayer:(WMPlayer *)wmplayer doubleTaped:(UITapGestureRecognizer *)doubleTap{
    NSLog(@"%s", __func__);
}
//WMPlayer的的操作栏隐藏和显示
-(void)wmplayer:(WMPlayer *)wmplayer isHiddenTopAndBottomView:(BOOL )isHidden{
    NSLog(@"%s", __func__);
}
///播放状态
//播放失败的代理方法
-(void)wmplayerFailedPlay:(WMPlayer *)wmplayer WMPlayerStatus:(WMPlayerState)state{
    NSLog(@"%s", __func__);
}
//准备播放的代理方法
-(void)wmplayerReadyToPlay:(WMPlayer *)wmplayer WMPlayerStatus:(WMPlayerState)state{
    NSLog(@"%s", __func__);
}
//播放完毕的代理方法
-(void)wmplayerFinishedPlay:(WMPlayer *)wmplayer{
    NSLog(@"%s", __func__);
}


@end



