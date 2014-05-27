//
//  Blend.h
//  Headblend
//
//  Created by Bastien Beurier on 5/27/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Blend : NSObject

+ (NSArray *)rawBlendsToInstances:(NSArray *)rawSnapbies;
+ (Blend *)rawBlendToInstance:(id)rawBlend;
- (NSURL *)getFirstBlendImageURL;
- (NSURL *)getSecondBlendImageURL;

@property (nonatomic) NSUInteger identifier;

@end
