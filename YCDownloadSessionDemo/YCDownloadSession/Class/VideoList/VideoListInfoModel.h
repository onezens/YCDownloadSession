//
//  VideoListInfoModel.h
//  YCDownloadSession
//
//  Created by wz on 17/3/23.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoListInfoModel : NSObject

@property (nonatomic, copy) NSString *vid;
@property (nonatomic, copy) NSString *m3u8_url;
@property (nonatomic, copy) NSString *video_url;
@property (nonatomic, copy) NSString *cover_url;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *video_desc;
@property (nonatomic, copy) NSString *file_type;
@property (nonatomic, assign) NSInteger file_size;


+ (NSMutableArray <VideoListInfoModel *> *)getVideoListInfo:(NSArray <NSDictionary *>*)listInfos;

+ (NSData *)dateWithInfoModel:(VideoListInfoModel *)mo;
+ (VideoListInfoModel *)infoWithData:(NSData *)data;

@end
