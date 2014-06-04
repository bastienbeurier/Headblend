//
//  PortraitImagePickerViewController.m
//  Headblend
//
//  Created by Bastien Beurier on 6/4/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "PortraitImagePickerViewController.h"

@interface PortraitImagePickerViewController ()

@end

@implementation PortraitImagePickerViewController

- (BOOL)shouldAutorotate{
    return NO;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

@end
