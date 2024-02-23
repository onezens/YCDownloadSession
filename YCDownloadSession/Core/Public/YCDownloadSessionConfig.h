//
//  YCDownloadSessionConfig.h
//  YCDownloadSession-library
//
//  Created by wz on 2022/2/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface YCDownloadSessionConfig : NSObject

/* identifier for the background session configuration */
@property (nonatomic, copy) NSString *identifier;

@property (nonatomic, strong) NSOperationQueue *queue;
@end

NS_ASSUME_NONNULL_END
