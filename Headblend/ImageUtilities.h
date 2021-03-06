//
//  ImageUtilities.h
//  Headblend
//
//  Created by Bastien Beurier on 5/22/14.
//  Copyright (c) 2014 Headblend. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageUtilities : NSObject

+ (void)outerGlow:(UIView *)view;

+ (void)hideBottomHalf:(UIView *)view  offset:(NSInteger)offset;

+ (void)hideTopHalf:(UIView *)view  offset:(NSInteger)offset;

+ (UIImage*)cropImage:(UIImage*)image toFitWidthOnHeightTargetRatio:(CGFloat)targetRatio andOrientate:(UIImageOrientation)orientation;

+ (UIImage*) cropBiggestCenteredSquareImageFromImage:(UIImage*)image withSide:(CGFloat)side;

+ (NSString *)encodeToBase64String:(UIImage *)image;

+ (UIImage *)resizeImage:(UIImage *)image;

@end
