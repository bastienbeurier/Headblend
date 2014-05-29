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

@property (weak, nonatomic) IBOutlet UIImage *firstPersonImage;
@property (weak, nonatomic) IBOutlet UIImage *secondPersonImage;

@property (weak, nonatomic) id <DisplayControllerDelegate> displayVCDelegate;

@end

@protocol DisplayControllerDelegate

@property (nonatomic) BOOL backFromDisplay;

@end