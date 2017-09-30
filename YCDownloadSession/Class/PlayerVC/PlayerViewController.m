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

@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = self.playerItem.fileName;
    
    _player = [[WMPlayer alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 300)];
    [self.view addSubview:_player];
    NSURL *url = [NSURL fileURLWithPath:self.playerItem.savePath];
    [_player setURLString:url.absoluteString];
    _player.delegate = self;
    [_player player];
}


#pragma mark - player view delegate


//点击播放暂停按钮代理方法
-(void)wmplayer:(WMPlayer *)wmplayer clickedPlayOrPauseButton:(UIButton *)playOrPauseBtn{
    NSLog(@"%s", __func__);
}
//点击关闭按钮代理方法
-(void)wmplayer:(WMPlayer *)wmplayer clickedCloseButton:(UIButton *)closeBtn{
    NSLog(@"%s", __func__);
}
//点击全屏按钮代理方法
-(void)wmplayer:(WMPlayer *)wmplayer clickedFullScreenButton:(UIButton *)fullScreenBtn{
    NSLog(@"%s", __func__);
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



