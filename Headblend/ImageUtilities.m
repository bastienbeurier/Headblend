//
//  ImageUtilities.m
//  Headblend
//
//  Created by Bastien Beurier on 5/22/14.
//  Copyright (c) 2014 Headblend. All rights reserved.
//

#import "ImageUtilities.h"

@implementation ImageUtilities

+ (void)outerGlow:(UIView *)view
{
    view.layer.shadowColor = [UIColor blackColor].CGColor;
    view.layer.shadowOffset = CGSizeMake(0.0, 0.0);
    view.layer.shadowRadius = 1;
    view.layer.shadowOpacity = 0.3;
    view.layer.masksToBounds = NO;
}

+ (void)hideBottomHalf:(UIView *)view
{
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.backgroundColor = [[UIColor clearColor] CGColor];
    CGRect maskRect = CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height / 2);
    
    // Create a path with the rectangle in it.
    CGPathRef path = CGPathCreateWithRect(maskRect, NULL);
    
    // Set the path to the mask layer.
    maskLayer.path = path;
    
    CGPathRelease(path);
    
    view.layer.mask = maskLayer;
}

+ (void)hideTopHalf:(UIView *)view
{
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.backgroundColor = [[UIColor clearColor] CGColor];
    CGRect maskRect = CGRectMake(0, view.bounds.size.height / 2, view.bounds.size.width, view.bounds.size.height / 2);
    
    // Create a path with the rectangle in it.
    CGPathRef path = CGPathCreateWithRect(maskRect, NULL);
    
    // Set the path to the mask layer.
    maskLayer.path = path;
    
    CGPathRelease(path);
    
    view.layer.mask = maskLayer;
}

+ (UIImage*)cropImage:(UIImage*)image toFitWidthOnHeightTargetRatio:(CGFloat)targetRatio andOrientate:(UIImageOrientation)orientation
{
    UIImageOrientation originalOrientation = image.imageOrientation;
    
    // Put orientation up before cropping
    image = [UIImage imageWithCGImage:image.CGImage
                                scale:1
                          orientation:UIImageOrientationUp];
    // Crop
    CGRect cropRect;
    CGFloat imageWidth = image.size.width;
    CGFloat imageHeight = image.size.height;
    if(imageWidth <= imageHeight) {
        orientation = originalOrientation;
    }
    CGFloat imageRatio = MIN(imageWidth,imageHeight) / MAX(imageWidth,imageHeight);
    
    if (imageRatio > targetRatio) {
        if (imageWidth <= imageHeight) {
            // Create rectangle from middle of current image
            CGFloat croppedWidth = (1 - targetRatio / imageRatio ) * imageWidth;
            cropRect = CGRectMake(croppedWidth / 2, 0.0, imageWidth - croppedWidth, imageHeight);
        } else {
            CGFloat croppedHeight = (1 - targetRatio / imageRatio ) * imageHeight;
            cropRect = CGRectMake(0.0, croppedHeight / 2, imageWidth, imageHeight - croppedHeight);
        }
    } else {
        if (imageWidth <= imageHeight) {
            // Create rectangle from middle of current image
            CGFloat croppedHeight = (1 - imageRatio / targetRatio) * imageHeight;
            cropRect = CGRectMake(0.0, croppedHeight / 2, imageWidth, imageHeight - croppedHeight);
        } else {
            CGFloat croppedWidth = (1 - imageRatio / targetRatio) * imageWidth;
            cropRect = CGRectMake(croppedWidth / 2, 0.0, imageWidth - croppedWidth, imageHeight);
        }
    }
    // Create new cropped UIImage
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef
                                                scale:1
                                          orientation:orientation];
    CGImageRelease(imageRef);
    return croppedImage;
}

+ (UIImage*) cropBiggestCenteredSquareImageFromImage:(UIImage*)image withSide:(CGFloat)side
{
    // Get size of current image
    CGSize size = [image size];
    if( size.width == size.height && size.width == side){
        return image;
    }
    
    CGSize newSize = CGSizeMake(side, side);
    double ratio;
    double delta;
    CGPoint offset;
    
    //make a new square size, that is the resized imaged width
    CGSize sz = CGSizeMake(newSize.width, newSize.width);
    
    //figure out if the picture is landscape or portrait, then
    //calculate scale factor and offset
    if (image.size.width > image.size.height) {
        ratio = newSize.height / image.size.height;
        delta = ratio*(image.size.width - image.size.height);
        offset = CGPointMake(delta/2, 0);
    } else {
        ratio = newSize.width / image.size.width;
        delta = ratio*(image.size.height - image.size.width);
        offset = CGPointMake(0, delta/2);
    }
    
    //make the final clipping rect based on the calculated values
    CGRect clipRect = CGRectMake(-offset.x, -offset.y,
                                 (ratio * image.size.width),
                                 (ratio * image.size.height));
    
    //start a new context, with scale factor 0.0 so retina displays get
    //high quality image
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]) {
        UIGraphicsBeginImageContextWithOptions(sz, YES, 0.0);
    } else {
        UIGraphicsBeginImageContext(sz);
    }
    UIRectClip(clipRect);
    [image drawInRect:clipRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

+ (NSString *)encodeToBase64String:(UIImage *)image {
    return [UIImageJPEGRepresentation(image,0.9) base64EncodedStringWithOptions:0];
}

@end
