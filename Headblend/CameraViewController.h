//
//  HeadblendViewController.h
//  Headblend
//
//  Created by Bastien Beurier on 5/22/14.
//  Copyright (c) 2014 Headblend. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DisplayViewController.h"

@interface CameraViewController : UIViewController <UIImagePickerControllerDelegate, DisplayControllerDelegate>

@property (nonatomic) UIImagePickerControllerSourceType sourceType;
@property (nonatomic) BOOL backFromDisplay;

@end
