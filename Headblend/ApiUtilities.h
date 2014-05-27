//
//  AFSnapbyAPIClient.h
//  snapby-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "AFHTTPSessionManager.h"

@interface ApiUtilities : AFHTTPSessionManager

+ (ApiUtilities *)sharedClient;

+ (void)saveEncodedBlend1:(NSString *)blend1 andBlend2:(NSString *)blend2;

+ (void)pullBlendsPage:(NSUInteger)page pageSize:(NSUInteger)pageSize
     AndExecuteSuccess:(void(^)(NSArray *snapbies, NSInteger page))successBlock failure:(void (^)())failureBlock;

@end

