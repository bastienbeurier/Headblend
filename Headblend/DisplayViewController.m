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
#import "Constants.h"

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

@property (weak, nonatomic) IBOutlet UIButton *filterButton;
@property (weak, nonatomic) IBOutlet UIButton *exposureFirstButton;
@property (weak, nonatomic) IBOutlet UIButton *exposureSecondButton;
@property (weak, nonatomic) IBOutlet UIButton *inverseButton;

@property (weak, nonatomic) IBOutlet UIView *tutorialView;
@property (strong, nonatomic) NSTimer *firstTutorialTimer;
@property (strong, nonatomic) NSTimer *secondTutorialTimer;
@property (nonatomic) NSUInteger tutorialIndex;

@property (nonatomic) float exposureLevel;
@property (nonatomic) NSUInteger filterIndex;

@property (nonatomic) CGFloat topScrollViewInitialContentOffsetY;
@property (weak, nonatomic) IBOutlet UILabel *tutorialLabel;
@property (weak, nonatomic) IBOutlet UIImageView *firstTutorialImage;

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
    
    self.tutorialIndex = 0;
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
    
    self.topScrollViewInitialContentOffsetY = self.topScrollView.contentOffset.y;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if (![userDefaults objectForKey:@"ADJUST FACE TUTO PREF"]) {
        self.tutorialView.hidden = NO;
        self.firstTutorialTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                         target:self
                                       selector:@selector(zoomAnimationOnFace)
                                       userInfo:nil
                                        repeats:YES];
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

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    
    NSArray *blends = [self getBlends];
    [self saveBlends:blends];
    
    self.topImageView.image = nil;
    self.bottomImageView.image = nil;
    self.firstPersonImageView.image = nil;
    self.secondPersonImageView.image = nil;
    
    self.firstPersonImage = nil;
    self.secondPersonImage = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)zoomAnimationOnFace
{
    if (self.topScrollView.contentOffset.y == self.topScrollViewInitialContentOffsetY) {
        [self.topScrollView setZoomScale:1.0 animated:YES];
    } else {
        [self.topScrollView setZoomScale:1.1 animated:YES];
        
        [self.topScrollView setContentOffset:CGPointMake(self.topScrollView.contentOffset.x, self.topScrollViewInitialContentOffsetY) animated:YES];
    }
}

- (NSArray *)getBlends
{
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
    
    return [[NSArray alloc] initWithObjects:image1, image2, nil];
}

- (void)saveBlends:(NSArray *)blends
{
    [ApiUtilities saveEncodedBlend1:[ImageUtilities encodeToBase64String:[blends objectAtIndex:0]] andBlend2:[ImageUtilities encodeToBase64String:[blends objectAtIndex:1]]];
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
    NSArray *blends = [self getBlends];
    [self saveBlends:blends];
    
    NSString *shareString = @"Download Jokeface.";
    
    //TODO: add App Store link
    NSURL *shareUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/us/app/jokeface/id%d?mt=8", APP_ID]];
    
    NSArray *activityItems = [NSArray arrayWithObjects:shareString, shareUrl, [blends objectAtIndex:0], [blends objectAtIndex:1], nil];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [activityViewController setValue:@"" forKey:@"subject"];
    activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop];
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (IBAction)inverseButtonClicked:(id)sender {
    if (self.blendIndex == 0) {
        [self secondBlend];
    } else {
        [self firstBlend];
    }
    
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = @(M_PI);
    rotationAnimation.duration = 0.5;
    rotationAnimation.autoreverses = NO;
    rotationAnimation.repeatCount = 0;
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.inverseButton.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
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
    if (self.filterIndex == 1) {
        self.topImageView.image = [self vintageFilter:[self exposureFilter:self.firstPersonImage value:self.exposureLevel]];
        self.bottomImageView.image = [self vintageFilter:[self exposureFilter:self.secondPersonImage value:-self.exposureLevel]];
        self.firstPersonImageView.image = self.topImageView.image;
        self.secondPersonImageView.image = self.bottomImageView.image;
    } else if (self.filterIndex == 2) {
        self.topImageView.image = [self washedOutFilter:[self exposureFilter:self.firstPersonImage value:self.exposureLevel]];
        self.bottomImageView.image = [self washedOutFilter:[self exposureFilter:self.secondPersonImage value:-self.exposureLevel]];        self.firstPersonImageView.image = self.topImageView.image;
        self.secondPersonImageView.image = self.bottomImageView.image;
    } else if (self.filterIndex == 3) {
        self.topImageView.image = [self blackAndWhiteFilter:[self exposureFilter:self.firstPersonImage value:self.exposureLevel]];
        self.bottomImageView.image = [self blackAndWhiteFilter:[self exposureFilter:self.secondPersonImage value:-self.exposureLevel]];
        self.firstPersonImageView.image = self.topImageView.image;
        self.secondPersonImageView.image = self.bottomImageView.image;
    } else {
        self.topImageView.image = [self exposureFilter:self.firstPersonImage value:self.exposureLevel];
        self.bottomImageView.image = [self exposureFilter:self.secondPersonImage value:-self.exposureLevel];
        self.firstPersonImageView.image = self.topImageView.image;
        self.secondPersonImageView.image = self.bottomImageView.image;
    }
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

- (IBAction)tutorialViewClicked:(id)sender {
    
    if (self.tutorialIndex == 0) {
        self.tutorialIndex = 1;
        [self.firstTutorialTimer invalidate];
        
        [self.topScrollView setZoomScale:1.1 animated:NO];
        
        [self centerScrollView:self.topScrollView];
        
        self.firstTutorialTimer = nil;
        
        self.firstTutorialImage.hidden = YES;
        
        [self.view insertSubview:self.inverseButton aboveSubview:self.tutorialView];
        
        self.secondTutorialTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                   target:self
                                                                 selector:@selector(inverseButtonClicked:)
                                                                 userInfo:nil
                                                                  repeats:YES];
        
        self.tutorialLabel.text = @"...inverse faces...";
    } else if (self.tutorialIndex == 1) {
        self.tutorialIndex = 2;
        [self.secondTutorialTimer invalidate];
        [self firstBlend];
        
        [self.view insertSubview:self.tutorialView aboveSubview:self.inverseButton];
        [self.view insertSubview:self.filterButton aboveSubview:self.tutorialView];
        
        self.tutorialLabel.text = @"...apply filters...";
    } else if (self.tutorialIndex == 2) {
        self.tutorialIndex = 3;
        
        [self.view insertSubview:self.tutorialView aboveSubview:self.filterButton];
        [self.view insertSubview:self.validateButton aboveSubview:self.tutorialView];
        
        self.tutorialLabel.text = @"...and save!";

    } else {
        self.tutorialView.hidden = YES;
    }
}

@end
