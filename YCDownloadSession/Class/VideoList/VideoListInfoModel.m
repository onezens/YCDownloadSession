//
//  VideoListInfoModel.m
//  YCDownloadSession
//
//  Created by wz on 17/3/23.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "VideoListInfoModel.h"

@implementation VideoListInfoModel

+ (NSArray<VideoListInfoModel *> *)getVideoListInfo:(NSArray<NSDictionary *> *)listInfos {
    
    NSMutableArray *arrM = [NSMutableArray array];
    for (NSDictionary *dict in listInfos) {
        VideoListInfoModel *model = [[VideoListInfoModel alloc] initWithDict:dict];
        [arrM addObject:model];
    }
    return arrM;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {}

- (instancetype)initWithDict:(NSDictionary *)dict {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

@end
