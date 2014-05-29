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

#define EXPOSURE_UNIT 0.05

@interface DisplayViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *topImageView;
@property (weak, nonatomic) IBOutlet UIImageView *bottomImageView;
@property (weak, nonatomic) IBOutlet UIImageView *firstPersonImageView;
@property (weak, nonatomic) IBOutlet UIImageView *secondPersonImageView;
@property (nonatomic) BOOL blendIndex;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *validateButton;
@property (strong, nonatomic) NSTimer *timer;
@property (weak, nonatomic) IBOutlet UIScrollView *topScrollView;
@property (weak, nonatomic) IBOutlet UIScrollView *bottomScrollView;

@property (strong, nonatomic) GPUImageSepiaFilter *sepiaFilter;
@property (strong, nonatomic) GPUImageContrastFilter *contrastFilter;
@property (strong, nonatomic) GPUImageExposureFilter *exposureFilter;
@property (strong, nonatomic) GPUImageLevelsFilter *levelsFilter;
@property (strong, nonatomic) GPUImageGrayscaleFilter *grayFilter;
@property (strong, nonatomic) GPUImageVignetteFilter *vignetteFilter;

@property (weak, nonatomic) IBOutlet UIButton *filterButton;
@property (weak, nonatomic) IBOutlet UIButton *exposureFirstButton;
@property (weak, nonatomic) IBOutlet UIButton *exposureSecondButton;
@property (weak, nonatomic) IBOutlet UIButton *inverseButton;

@property (strong, nonatomic) UIActionSheet *actionSheet;

@property (weak, nonatomic) IBOutlet UIView *tutorialView;


@property (nonatomic) float exposureLevel;
@property (nonatomic) NSUInteger filterIndex;


@end

@implementation DisplayViewController

- (void)toggleBlend
{
    if (self.blendIndex == 0) {
        [self secondBlend];
    } else {
        [self firstBlend];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setUpFilters];
    
    self.exposureLevel = 0;
    self.filterIndex = 0;
    
    self.topImageView.image = self.firstPersonImage;
    self.bottomImageView.image = self.secondPersonImage;
    self.firstPersonImageView.image = self.firstPersonImage;
    self.secondPersonImageView.image = self.secondPersonImage;
    
    self.topScrollView.delegate = self;
    self.bottomScrollView.delegate = self;
    
    self.topScrollView.zoomScale = 1.1;
    self.bottomScrollView.zoomScale = 1.1;
    
    [self centerScrollView:self.topScrollView];
    [self centerScrollView:self.bottomScrollView];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if (![userDefaults objectForKey:@"ADJUST FACE TUTO PREF"]) {
        self.tutorialView.hidden = NO;
    } else {
        self.tutorialView.hidden = YES;
    }
    
    [userDefaults setObject:@"dummy" forKey:@"ADJUST FACE TUTO PREF"];
    
    [self firstBlend];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.topImageView.bounds = CGRectMake(0, 0, self.topScrollView.bounds.size.width, self.topScrollView.bounds.size.height);
    self.bottomImageView.bounds = CGRectMake(0, 0, self.bottomImageView.bounds.size.width, self.bottomImageView.bounds.size.height);
}

- (void)centerScrollView:(UIScrollView *)scrollView
{
    CGFloat newContentOffsetX = (scrollView.contentSize.width/2) - (scrollView.bounds.size.width/2);
    CGFloat newContentOffsetY = (scrollView.contentSize.height/2) - (scrollView.bounds.size.height/2);
    scrollView.contentOffset = CGPointMake(newContentOffsetX, newContentOffsetY);
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
    
    [self.topScrollView addSubview:self.topImageView];
    [self.view insertSubview:self.topScrollView aboveSubview:self.bottomScrollView];
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
    
    [self.bottomScrollView addSubview:self.bottomImageView];
    [self.view insertSubview:self.bottomScrollView aboveSubview:self.topScrollView];
}

- (IBAction)backButtonClicked:(id)sender {
    self.displayVCDelegate.backFromDisplay = YES;
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)validateButtonClicked:(id)sender {
    self.actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                   delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Publish", @"Share or save", nil];
    [self.actionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (IBAction)inverseButtonClicked:(id)sender {
    if (self.blendIndex == 0) {
        [self secondBlend];
    } else {
        [self firstBlend];
    }
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
{}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    if (scrollView == self.topScrollView) {
        return self.topImageView;
    } else {
        return self.bottomImageView;
    }
}

- (void)updateImagesFilters
{
    UIImage *topImage = [self exposureFilter:self.firstPersonImage value:self.exposureLevel];
    UIImage *bottomImage = [self exposureFilter:self.secondPersonImage value:-self.exposureLevel];
    
    if (self.filterIndex == 1) {
        topImage = [self vintageFilter:topImage];
        bottomImage = [self vintageFilter:bottomImage];
    } else if (self.filterIndex == 2) {
        topImage = [self washedOutFilter:topImage];
        bottomImage = [self washedOutFilter:bottomImage];
    } else if (self.filterIndex == 3) {
        topImage = [self blackAndWhiteFilter:topImage];
        bottomImage = [self blackAndWhiteFilter:bottomImage];
    }
    
    [self.vignetteFilter setVignetteEnd:0.9];
    
    topImage = [self.vignetteFilter imageByFilteringImage:topImage];
    bottomImage = [self.vignetteFilter imageByFilteringImage:bottomImage];
 
    self.topImageView.image = topImage;
    self.bottomImageView.image = bottomImage;
    self.firstPersonImageView.image = topImage;
    self.secondPersonImageView.image = bottomImage;
}

- (IBAction)plusExpositionButtonClicked:(id)sender {
    self.exposureLevel = self.exposureLevel + EXPOSURE_UNIT;
    [self updateImagesFilters];
}

- (IBAction)minusExpositionButtonClicked:(id)sender {
    self.exposureLevel = self.exposureLevel - EXPOSURE_UNIT;
    [self updateImagesFilters];

}

- (void)setUpFilters
{
    self.sepiaFilter = [[GPUImageSepiaFilter alloc] init];
    self.contrastFilter = [[GPUImageContrastFilter alloc] init];
    self.exposureFilter = [[GPUImageExposureFilter alloc] init];
    self.levelsFilter = [[GPUImageLevelsFilter alloc] init];
    self.grayFilter = [[GPUImageGrayscaleFilter alloc] init];
    self.vignetteFilter = [[GPUImageVignetteFilter alloc] init];
}

- (IBAction)changeFilter:(id)sender {
    if (self.filterIndex < 3) {
        self.filterIndex = self.filterIndex + 1;
    } else {
        self.filterIndex = 0;
    }
    
    [self updateImagesFilters];
}

- (UIImage *)exposureFilter:(UIImage *)image value:(float)value
{
    [self.exposureFilter setExposure:value];
    return [self.exposureFilter imageByFilteringImage:image];

}

- (UIImage *)vintageFilter:(UIImage *)image
{
    // 0 - 1
    [self.sepiaFilter setIntensity:1.0];
    
    //0 - 4
    [self.contrastFilter setContrast:1.2];
    
    // - 4 - 4
    [self.exposureFilter setExposure:0.2];
    
    image = [self.sepiaFilter imageByFilteringImage:image];
    image = [self.contrastFilter imageByFilteringImage:image];
    return [self.exposureFilter imageByFilteringImage:image];
}

- (UIImage *)washedOutFilter:(UIImage *)image
{
    [self.levelsFilter setRedMin:0.25 gamma:1.0 max:0.8 minOut:0.0 maxOut:1.0];
    [self.levelsFilter setGreenMin:0.15 gamma:1.0 max:0.8 minOut:0.0 maxOut:1.0];
    [self.levelsFilter setBlueMin:0.03 gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
    
    //0 - 4
    [self.contrastFilter setContrast:0.8];
    
    // - 4 - 4
    [self.exposureFilter setExposure:0.2];
    
    image = [self.levelsFilter imageByFilteringImage:image];
    image = [self.contrastFilter imageByFilteringImage:image];
    return [self.exposureFilter imageByFilteringImage:image];
}

- (UIImage *)blackAndWhiteFilter:(UIImage *)image
{
    return [self.grayFilter imageByFilteringImage:image];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:@"Cancel"]) {
        return;
    }
    
    self.backButton.hidden = YES;
    self.validateButton.hidden = YES;
    self.filterButton.hidden = YES;
    self.exposureFirstButton.hidden = YES;
    self.exposureSecondButton.hidden = YES;
    self.inverseButton.hidden = YES;
    
    UIGraphicsBeginImageContext(self.view.bounds.size);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image1 = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self inverseButtonClicked:nil];
    
    UIGraphicsBeginImageContext(self.view.bounds.size);
    [self.view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image2 = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    [self inverseButtonClicked:nil];
    
    self.backButton.hidden = NO;
    self.validateButton.hidden = NO;
    self.filterButton.hidden = NO;
    self.exposureFirstButton.hidden = NO;
    self.exposureSecondButton.hidden = NO;
    self.inverseButton.hidden = NO;
    
    if ([buttonTitle isEqualToString:@"Publish"]) {
        
        [ApiUtilities saveEncodedBlend1:[ImageUtilities encodeToBase64String:image1] andBlend2:[ImageUtilities encodeToBase64String:image2]];
    } else {
        //TODO: change app name
        NSString *shareString = @"";
        
        //TODO: add App Store link
        NSURL *shareUrl = [NSURL URLWithString:@""];
        
        NSArray *activityItems = [NSArray arrayWithObjects:shareString, shareUrl, image1, image2, nil];
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        [activityViewController setValue:@"" forKey:@"subject"];
        activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop];
        
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
    
}
- (IBAction)tutorialViewClicked:(id)sender {
    self.tutorialView.hidden = YES;
}
@end
