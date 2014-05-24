//
//  AFSnapbyAPIClient.m
//  snapby-ios
//
//  Created by Bastien Beurier on 7/17/13.
//  Copyright (c) 2013 Snapby. All rights reserved.
//

#import "ApiUtilities.h"
#import "Constants.h"

@implementation ApiUtilities

// ---------------
// Utilities
// ---------------

+ (ApiUtilities *)sharedClient
{
    static ApiUtilities *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[ApiUtilities alloc] initWithBaseURL:[NSURL URLWithString:kProdAFSnapbyAPIBaseURLString]];

        NSOperationQueue *operationQueue = _sharedClient.operationQueue;
        [_sharedClient.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            if(status == AFNetworkReachabilityStatusNotReachable) {
                [operationQueue cancelAllOperations];
            }
        }];
    });
    
    return _sharedClient;
}

+ (NSString *)getBasePath
{
    return [NSString stringWithFormat:@"api/v%@/", kApiVersion];
}

- (id)initWithBaseURL:(NSURL *)url
{
    self = [super initWithBaseURL:url];
    
    if (!self) {
        return nil;
    }
    
    return self;
}

// Snapby creation
+ (void)saveEncodedImage:(NSString *)encodedImage
{    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] initWithCapacity:10];
    
    ApiUtilities *manager = [ApiUtilities sharedClient];
    
    [parameters setObject:encodedImage forKey:@"headblend"];
    
    NSString *path = [[ApiUtilities getBasePath] stringByAppendingString:@"headblend.json"];
    
    [manager POST:path parameters:parameters success:nil failure:nil];
}

@end
