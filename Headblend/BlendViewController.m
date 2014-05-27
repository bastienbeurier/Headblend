//
//  BlendViewController.m
//  Headblend
//
//  Created by Bastien Beurier on 5/27/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "BlendViewController.h"
#import "UIImageView+AFNetworking.h"

@interface BlendViewController ()

@property (strong, nonatomic) Blend *blend;

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *secondImageView;
@property (weak, nonatomic) IBOutlet UIButton *inverseButton;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (nonatomic) BOOL loadingFailed;
@property (nonatomic) BOOL firstImageLoaded;
@property (nonatomic) BOOL secondImageLoaded;

@property (nonatomic, strong) UIActivityIndicatorView *activityView;

@end

@implementation BlendViewController

- (id)initWithBlend:(Blend *)blend;
{
    if (self = [super initWithNibName:@"BlendViewController" bundle:nil])
    {
        self.blend = blend;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadImage];
}

- (IBAction)inverseButtonClicked:(id)sender {
    if (self.imageView.hidden) {
        self.imageView.hidden = NO;
        self.secondImageView.hidden = YES;
    } else {
        self.imageView.hidden = YES;
        self.secondImageView.hidden = NO;
    }
}

- (IBAction)refreshButtonClicked:(id)sender {
    [self loadImage];
}

- (void)loadImage
{
    self.loadingFailed = NO;
    self.firstImageLoaded = NO;
    self.secondImageLoaded = NO;
    
    self.imageView.hidden = YES;
    self.secondImageView.hidden = YES;
    self.inverseButton.hidden = YES;
    self.refreshButton.hidden = YES;
    
    [self showLoadingIndicator];
    
    NSURLRequest *firstImageRequest = [NSURLRequest requestWithURL:[self.blend getFirstBlendImageURL]];
    NSURLRequest *secondImageRequest = [NSURLRequest requestWithURL:[self.blend getSecondBlendImageURL]];
    
    [self.imageView setImageWithURLRequest:firstImageRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        self.imageView.image = image;
        self.firstImageLoaded = YES;
        
        if (!self.loadingFailed && self.secondImageLoaded) {
            self.imageView.hidden = NO;
            self.inverseButton.hidden = NO;
            
            [self hideLoadingIndicator];
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        self.loadingFailed = YES;
        
        self.refreshButton.hidden = NO;
        
        self.imageView.hidden = YES;
        self.secondImageView.hidden = YES;
        self.inverseButton.hidden = YES;
        [self hideLoadingIndicator];

    }];
    
    [self.secondImageView setImageWithURLRequest:secondImageRequest placeholderImage:nil success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
        self.secondImageView.image = image;
        self.secondImageLoaded = YES;
        
        if (!self.loadingFailed && self.firstImageLoaded) {
            
            self.imageView.hidden = NO;
            self.inverseButton.hidden = NO;
            
            [self hideLoadingIndicator];
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
        self.loadingFailed = YES;
        
        self.refreshButton.hidden = NO;
        
        self.imageView.hidden = YES;
        self.secondImageView.hidden = YES;
        self.inverseButton.hidden = YES;
        [self hideLoadingIndicator];
    }];
}

- (void)showLoadingIndicator
{
    if (!self.activityView) {
        self.activityView=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.activityView.center = self.view.center;
    }
    
    [self.activityView startAnimating];
    [self.view addSubview:self.activityView];
}

- (void)hideLoadingIndicator
{
    [self.activityView stopAnimating];
    [self.activityView removeFromSuperview];
}

@end
