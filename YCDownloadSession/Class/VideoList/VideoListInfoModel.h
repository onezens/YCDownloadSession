//
//  VideoListInfoModel.h
//  YCDownloadSession
//
//  Created by wz on 17/3/23.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoListInfoModel : NSObject

@property (nonatomic, copy) NSString *m3u8_url;
@property (nonatomic, copy) NSString *mp4_url;
@property (nonatomic, copy) NSString *cover;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *ptime;
@property (nonatomic, copy) NSString *videosource;
@property (nonatomic, copy) NSString *file_id;

+ (NSArray <VideoListInfoModel *> *)getVideoListInfo:(NSArray <NSDictionary *>*)listInfos;

@end
