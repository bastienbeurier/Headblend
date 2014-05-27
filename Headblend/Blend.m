//
//  Blend.m
//  Headblend
//
//  Created by Bastien Beurier on 5/27/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "Blend.h"
#import "Constants.h"

#define BLEND_ID @"id"

@implementation Blend

+ (Blend *)rawBlendToInstance:(NSDictionary *)rawBlend
{
    Blend *blend = [[Blend alloc] init];
    blend.identifier = [[rawBlend objectForKey:BLEND_ID] integerValue];
    
    return blend;
}

+ (NSArray *)rawBlendsToInstances:(NSArray *)rawBlends
{
    NSMutableArray *blends = [[NSMutableArray alloc] init];
    
    for (NSDictionary *rawBlend in rawBlends) {
        [blends addObject:[Blend rawBlendToInstance:rawBlend]];
    }
    
    return blends;
}

- (NSURL *)getFirstBlendImageURL
{
    return [NSURL URLWithString:[kProdBlendBaseURL stringByAppendingFormat:@"%lu_blend1",(unsigned long)self.identifier]];
}

- (NSURL *)getSecondBlendImageURL
{
    return [NSURL URLWithString:[kProdBlendBaseURL stringByAppendingFormat:@"%lu_blend2",(unsigned long)self.identifier]];
}

@end
