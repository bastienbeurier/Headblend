//
//  ShareViewController.m
//  Headblend
//
//  Created by Bastien Beurier on 5/22/14.
//  Copyright (c) 2014 Headblend. All rights reserved.
//

#import "DisplayViewController.h"
#import "ImageUtilities.h"
#import "GPUImage.h"
#import "ApiUtilities.h"

@interface DisplayViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *topImageView;
@property (weak, nonatomic) IBOutlet UIImageView *bottomImageView;
@property (weak, nonatomic) IBOutlet UIImageView *firstPersonImageView;
@property (weak, nonatomic) IBOutlet UIImageView *secondPersonImageView;
@property (nonatomic) BOOL blendIndex;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *validateButton;

@end

@implementation DisplayViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    GPUImageGrayscaleFilter *grayFilter = [[GPUImageGrayscaleFilter alloc] init];
    self.firstPersonImage = [grayFilter imageByFilteringImage:self.firstPersonImage];
    self.secondPersonImage = [grayFilter imageByFilteringImage:self.secondPersonImage];
    
    self.topImageView.image = self.firstPersonImage;
    self.bottomImageView.image = self.secondPersonImage;
    self.firstPersonImageView.image = self.firstPersonImage;
    self.secondPersonImageView.image = self.secondPersonImage;
    
    [self firstBlend];
}

-(BOOL)prefersStatusBarHidden { return YES; }

- (void)firstBlend
{
    self.blendIndex = 0;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.topImageView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:1] CGColor], (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0] CGColor], nil];
    
    gradient.startPoint = CGPointMake(0.5, 0.45f);
    gradient.endPoint = CGPointMake(0.5f, 0.5f);
    
    self.topImageView.layer.mask = gradient;
    
    self.bottomImageView.layer.mask = nil;
    
    [self.view insertSubview:self.topImageView atIndex:1];
}

- (void)secondBlend
{
    self.blendIndex = 1;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.topImageView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:1] CGColor], (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0] CGColor], nil];
    
    gradient.startPoint = CGPointMake(0.5, 0.45f);
    gradient.endPoint = CGPointMake(0.5f, 0.5f);
    
    self.bottomImageView.layer.mask = gradient;
    self.topImageView.layer.mask = nil;
    
    [self.view insertSubview:self.bottomImageView atIndex:1];
}

- (IBAction)backButtonClicked:(id)sender {
    self.displayVCDelegate.backFromDisplay = YES;
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)validateButtonClicked:(id)sender {
    self.backButton.hidden = YES;
    self.validateButton.hidden = YES;
    
    UIGraphicsBeginImageContext(self.view.bounds.size);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [ApiUtilities saveEncodedImage:[ImageUtilities encodeToBase64String:image]];
    
    //TODO: change app name
    NSString *shareString = @"Download Headblend for iPhone.";
    
    //TODO: add App Store link
    NSURL *shareUrl = [NSURL URLWithString:@"http://itunes.com/apps/headblend"];
    
    NSArray *activityItems = [NSArray arrayWithObjects:shareString, shareUrl, image, nil];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [activityViewController setValue:@"Sharing a blend with you!" forKey:@"subject"];
    activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop];
    
    [activityViewController setCompletionHandler:^(NSString *activityType, BOOL completed) {
        self.backButton.hidden = NO;
        self.validateButton.hidden = NO;
    }];
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (IBAction)blendButtonClicked:(id)sender {
    if (self.blendIndex == 0) {
        [self secondBlend];
    } else {
        [self firstBlend];
    }
}

@end
