//
//  ShareViewController.h
//  Headblend
//
//  Created by Bastien Beurier on 5/22/14.
//  Copyright (c) 2014 Headblend. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DisplayControllerDelegate;

@interface DisplayViewController : UIViewController <UIScrollViewDelegate>

@property (weak, nonatomic) UIImage *firstPersonImage;
@property (weak, nonatomic) UIImage *secondPersonImage;
@property (weak, nonatomic) UIImage *firstPersonImageFiltered;
@property (weak, nonatomic) UIImage *secondPersonImageFiltered;


@property (weak, nonatomic) id <DisplayControllerDelegate> displayVCDelegate;

- (NSArray *)getBlends;
- (void)saveBlends:(NSArray *)blends;

@end

@protocol DisplayControllerDelegate

@property (nonatomic) BOOL backFromDisplay;

@end