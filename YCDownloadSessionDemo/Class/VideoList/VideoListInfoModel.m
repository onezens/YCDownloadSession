//
//  VideoListInfoModel.m
//  YCDownloadSession
//
//  Created by wz on 17/3/23.
//  Copyright © 2017年 onezen.cc. All rights reserved.
//

#import "VideoListInfoModel.h"
#import <objc/runtime.h>

@implementation VideoListInfoModel

+ (NSMutableArray<VideoListInfoModel *> *)getVideoListInfo:(NSArray<NSDictionary *> *)listInfos {
    NSMutableArray *arrM = [NSMutableArray array];
    for (NSDictionary *dict in listInfos) {
        VideoListInfoModel *model = [[VideoListInfoModel alloc] initWithDict:dict];
        if ([model.vid isKindOfClass:[NSNumber class]]) {
            model.vid = [(NSNumber *)model.vid stringValue];
        }
        [arrM addObject:model];
    }
    return arrM;
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {}

- (void)setNilValueForKey:(NSString *)key{}

- (instancetype)initWithDict:(NSDictionary *)dict {
    if (self = [super init]) {
        [self setValuesForKeysWithDictionary:dict];
    }
    return self;
}

- (NSArray *)getAllKeys{
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList(self.class, &count);
    NSMutableArray *keys = [NSMutableArray array];
    for (int i=0; i<count; i++) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        [keys addObject:[NSString stringWithUTF8String:name]];
    }
    return keys;
}

+ (NSData *)dateWithInfoModel:(VideoListInfoModel *)mo {
    NSDictionary *dict = [mo dictionaryWithValuesForKeys:[mo getAllKeys]];
    return [NSJSONSerialization dataWithJSONObject:dict options:0 error:nil];
}
+ (VideoListInfoModel *)infoWithData:(NSData *)data {
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    VideoListInfoModel *mo = [[VideoListInfoModel alloc] initWithDict:dict];
    return mo;
}

@end
