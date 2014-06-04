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

@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *flipButton;

@property (weak, nonatomic) IBOutlet UIView *tutorialView;
@property (strong, nonatomic) NSTimer *tutorialTimer;
@property (weak, nonatomic) IBOutlet UIView *tutorialInstructionContainer;

@property (nonatomic) NSUInteger filterIndex;

@property (nonatomic) CGFloat topScrollViewInitialContentOffsetY;
@property (weak, nonatomic) IBOutlet UIImageView *firstTutorialImage;
@property (weak, nonatomic) IBOutlet UIImageView *logo;

@property (nonatomic) float firstBlendStartY;
@property (nonatomic) float secondBlendStartY;

@property (weak, nonatomic) IBOutlet UISlider *imageBorderSlider;
@property (weak, nonatomic) IBOutlet UISlider *secondImageExposureSlider;
@property (weak, nonatomic) IBOutlet UISlider *firstImageExposureSlider;

@property (weak, nonatomic) IBOutlet UIButton *firstFilterButton;
@property (weak, nonatomic) IBOutlet UIButton *secondFilterButton;
@property (weak, nonatomic) IBOutlet UIButton *thirdFilterButton;
@property (weak, nonatomic) IBOutlet UIButton *fourthFilterButton;

@property (nonatomic) BOOL editionMode;
@property (weak, nonatomic) IBOutlet UILabel *waterMark;

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
    
    self.editionMode = NO;
    
    [self.firstFilterButton.layer setCornerRadius:5.0];
    [self.secondFilterButton.layer setCornerRadius:5.0];
    [self.thirdFilterButton.layer setCornerRadius:5.0];
    [self.fourthFilterButton.layer setCornerRadius:5.0];
    
    [self.tutorialInstructionContainer.layer setCornerRadius:10.0];
    
    [self setFilterButtonBorder:self.firstFilterButton];
    
    self.firstBlendStartY = 0.5;
    self.secondBlendStartY = 0.5;
    
    [self.imageBorderSlider setMinimumValue:0.0];
    [self.imageBorderSlider setMaximumValue:1.0];
    [self.imageBorderSlider setValue:0.5];
    
    [self.firstImageExposureSlider setMinimumValue:-2.0];
    [self.firstImageExposureSlider setMaximumValue:2.0];
    [self.firstImageExposureSlider setValue:0.0];
    
    [self.secondImageExposureSlider setMinimumValue:-2.0];
    [self.secondImageExposureSlider setMaximumValue:2.0];
    [self.secondImageExposureSlider setValue:0.0];
    
    self.firstPersonImageFiltered = self.firstPersonImage;
    self.secondPersonImageFiltered = self.secondPersonImage;
    
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
    
    [self firstBlend];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.topImageView.bounds = CGRectMake(0, 0, self.topScrollView.bounds.size.width, self.topScrollView.bounds.size.height);
    self.bottomImageView.bounds = CGRectMake(0, 0, self.bottomImageView.bounds.size.width, self.bottomImageView.bounds.size.height);
    
    self.topScrollViewInitialContentOffsetY = self.topScrollView.contentOffset.y;
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if (![userDefaults objectForKey:@"ADJUST FACE TUTO PREF"]) {
        self.tutorialView.hidden = NO;
        self.editButton.hidden = YES;
        self.validateButton.hidden = YES;
        self.backButton.hidden = YES;
        self.flipButton.hidden = YES;
        
        self.tutorialTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                              target:self
                                                            selector:@selector(zoomAnimationOnFace)
                                                            userInfo:nil
                                                             repeats:YES];
    } else {
        self.tutorialView.hidden = YES;
    }
    
    [userDefaults setObject:@"dummy" forKey:@"ADJUST FACE TUTO PREF"];
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

- (NSArray *)getBlends
{
    self.backButton.hidden = YES;
    self.validateButton.hidden = YES;
    self.editButton.hidden = YES;
    self.flipButton.hidden = YES;
    self.logo.hidden = NO;
    
    self.waterMark.hidden = NO;
    
    [ImageUtilities outerGlow:self.waterMark];
    
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
    self.editButton.hidden = NO;
    self.flipButton.hidden = NO;
    self.logo.hidden = YES;
    
    self.waterMark.hidden = YES;
    
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
    self.imageBorderSlider.value = self.firstBlendStartY;
    
    self.blendIndex = 0;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.topImageView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:1] CGColor], (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0] CGColor], nil];
    
    gradient.startPoint = CGPointMake(0.5, self.imageBorderSlider.value);
    gradient.endPoint = CGPointMake(0.5f, self.imageBorderSlider.value + 0.05f);
    
    self.topImageView.layer.mask = gradient;
    
    self.bottomImageView.layer.mask = nil;
    
    [self.topScrollView addSubview:self.topImageView];
    [self.view insertSubview:self.topScrollView aboveSubview:self.bottomScrollView];
}

- (void)secondBlend
{
    self.imageBorderSlider.value = self.secondBlendStartY;
    
    self.blendIndex = 1;
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = self.topImageView.bounds;
    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:1] CGColor], (id)[[UIColor colorWithRed:0 green:0 blue:0 alpha:0] CGColor], nil];
    
    gradient.startPoint = CGPointMake(0.5, self.imageBorderSlider.value);
    gradient.endPoint = CGPointMake(0.5f, self.imageBorderSlider.value + 0.05f);
    
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
    if (self.editionMode) {
        [self editButtonClicked:nil];
    }
    
    NSArray *blends = [self getBlends];
    [self saveBlends:blends];
    
    NSString *shareString = @"Download Selflip.";
    
    //TODO: add App Store link
    NSURL *shareUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://itunes.apple.com/us/app/selflip/id%d?mt=8", APP_ID]];
    
    NSArray *activityItems = [NSArray arrayWithObjects:shareString, shareUrl, [blends objectAtIndex:0], [blends objectAtIndex:1], nil];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    [activityViewController setValue:@"" forKey:@"subject"];
    activityViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    activityViewController.excludedActivityTypes = @[UIActivityTypePrint, UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList, UIActivityTypeAirDrop];
    
    [self presentViewController:activityViewController animated:YES completion:nil];
}

- (IBAction)inverseButtonClicked:(id)sender {
    [self toggleBlend];
    
    CABasicAnimation *rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = @(M_PI);
    rotationAnimation.duration = 0.5;
    rotationAnimation.autoreverses = NO;
    rotationAnimation.repeatCount = 0;
    rotationAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [self.flipButton.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
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

- (void)updateFilter
{
    if (self.filterIndex == 1) {
        self.firstPersonImageFiltered = [self vintageFilter:self.firstPersonImage];
        self.secondPersonImageFiltered = [self vintageFilter:self.secondPersonImage];
    } else if (self.filterIndex == 2) {
        self.firstPersonImageFiltered = [self washedOutFilter:self.firstPersonImage];
        self.secondPersonImageFiltered = [self washedOutFilter:self.secondPersonImage];
    } else if (self.filterIndex == 3) {
        self.firstPersonImageFiltered = [self blackAndWhiteFilter:self.firstPersonImage];
        self.secondPersonImageFiltered = [self blackAndWhiteFilter:self.secondPersonImage];
    } else {
        self.firstPersonImageFiltered = self.firstPersonImage;
        self.secondPersonImageFiltered = self.secondPersonImage;
    }
    
    self.topImageView.image = [self exposureFilter:self.firstPersonImageFiltered value:self.firstImageExposureSlider.value];
    self.bottomImageView.image = [self exposureFilter:self.secondPersonImageFiltered value:self.secondImageExposureSlider.value];
    
    self.firstPersonImageView.image = self.topImageView.image;
    self.secondPersonImageView.image = self.bottomImageView.image;
}

- (void)updateExposureForImage:(NSUInteger)image
{
    if (image == 1) {
        if (self.firstPersonImageFiltered == nil) {
            if (self.filterIndex == 1) {
                self.firstPersonImageFiltered = [self vintageFilter:self.firstPersonImage];
            } else if (self.filterIndex == 2) {
                self.firstPersonImageFiltered = [self washedOutFilter:self.firstPersonImage];
            } else if (self.filterIndex == 3) {
                self.firstPersonImageFiltered = [self blackAndWhiteFilter:self.firstPersonImage];
            } else {
                self.firstPersonImageFiltered = self.firstPersonImage;
            }
        }
        
        self.topImageView.image = [self exposureFilter:self.firstPersonImageFiltered value:self.firstImageExposureSlider.value];
        self.firstPersonImageView.image = self.topImageView.image;
    } else {
        if (self.secondPersonImageFiltered == nil) {
            if (self.filterIndex == 1) {
                self.secondPersonImageFiltered = [self vintageFilter:self.secondPersonImage];
            } else if (self.filterIndex == 2) {
                self.secondPersonImageFiltered = [self washedOutFilter:self.secondPersonImage];
            } else if (self.filterIndex == 3) {
                self.secondPersonImageFiltered = [self blackAndWhiteFilter:self.secondPersonImage];
            } else {
                self.secondPersonImageFiltered = self.secondPersonImage;
            }
        }
        
        self.bottomImageView.image = [self exposureFilter:self.secondPersonImageFiltered value:self.secondImageExposureSlider.value];
        self.secondPersonImageView.image = self.bottomImageView.image;
    }
}

- (void)setUpFilters
{
    self.sepiaFilter = [[GPUImageSepiaFilter alloc] init];
    self.contrastFilter = [[GPUImageContrastFilter alloc] init];
    self.exposureFilter = [[GPUImageExposureFilter alloc] init];
    self.levelsFilter = [[GPUImageLevelsFilter alloc] init];
    self.grayFilter = [[GPUImageGrayscaleFilter alloc] init];
}

- (IBAction)editButtonClicked:(id)sender {
    if (self.editionMode) {
        self.editionMode = NO;
        
        self.firstPersonImageView.frame = CGRectMake(self.firstPersonImageView.frame.size.width * 2,
                                                     self.firstPersonImageView.frame.origin.y ,
                                                     self.firstPersonImageView.frame.size.width,
                                                     self.firstPersonImageView.frame.size.height);
        
        self.secondPersonImageView.frame = CGRectMake(self.firstPersonImageView.frame.size.width * 3,
                                                      self.secondPersonImageView.frame.origin.y ,
                                                      self.secondPersonImageView.frame.size.width,
                                                      self.secondPersonImageView.frame.size.height);
        
        self.firstPersonImageView.hidden = NO;
        self.secondPersonImageView.hidden = NO;
        
        [UIView animateWithDuration:0.3 animations:^{  // animate the following:
            
            self.firstPersonImageView.frame = CGRectMake(0,
                                                         self.firstPersonImageView.frame.origin.y ,
                                                         self.firstPersonImageView.frame.size.width,
                                                         self.firstPersonImageView.frame.size.height);
            
            self.secondPersonImageView.frame = CGRectMake(self.firstPersonImageView.frame.size.width,
                                                          self.secondPersonImageView.frame.origin.y ,
                                                          self.secondPersonImageView.frame.size.width,
                                                          self.secondPersonImageView.frame.size.height);
        }];
    } else {
        self.editionMode = YES;
        
        self.firstPersonImageView.frame = CGRectMake(0,
                                                     self.firstPersonImageView.frame.origin.y ,
                                                     self.firstPersonImageView.frame.size.width,
                                                     self.firstPersonImageView.frame.size.height);
        
        self.secondPersonImageView.frame = CGRectMake(self.firstPersonImageView.frame.size.width,
                                                      self.secondPersonImageView.frame.origin.y ,
                                                      self.secondPersonImageView.frame.size.width,
                                                      self.secondPersonImageView.frame.size.height);
        
        [UIView animateWithDuration:0.3 animations:^{  // animate the following:
            self.firstPersonImageView.frame = CGRectMake(self.firstPersonImageView.frame.size.width * 2,
                                                         self.firstPersonImageView.frame.origin.y ,
                                                         self.firstPersonImageView.frame.size.width,
                                                         self.firstPersonImageView.frame.size.height);
            
            self.secondPersonImageView.frame = CGRectMake(self.firstPersonImageView.frame.size.width * 3,
                                                          self.secondPersonImageView.frame.origin.y ,
                                                          self.secondPersonImageView.frame.size.width,
                                                          self.secondPersonImageView.frame.size.height);
        } completion:^(BOOL b){
            self.firstPersonImageView.hidden = YES;
            self.secondPersonImageView.hidden = YES;
        }];
    }
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
//    [self.contrastFilter setContrast:1.2];
    
    return [self.sepiaFilter imageByFilteringImage:image];
//    return [self.contrastFilter imageByFilteringImage:image];
}

- (UIImage *)washedOutFilter:(UIImage *)image
{
    [self.levelsFilter setRedMin:0.25 gamma:1.0 max:0.8 minOut:0.0 maxOut:1.0];
    [self.levelsFilter setGreenMin:0.15 gamma:1.0 max:0.8 minOut:0.0 maxOut:1.0];
    [self.levelsFilter setBlueMin:0.03 gamma:1.0 max:1.0 minOut:0.0 maxOut:1.0];
    
    //0 - 4
//    [self.contrastFilter setContrast:0.8];
    
    return [self.levelsFilter imageByFilteringImage:image];
//    return [self.contrastFilter imageByFilteringImage:image];
}

- (UIImage *)blackAndWhiteFilter:(UIImage *)image
{
    return [self.grayFilter imageByFilteringImage:image];
}

- (IBAction)tutorialViewClicked:(id)sender {
    //Consume event
}

- (IBAction)dismissTutorialClicked:(id)sender {
    self.tutorialView.hidden = YES;
    self.editButton.hidden = NO;
    self.validateButton.hidden = NO;
    self.backButton.hidden = NO;
    self.flipButton.hidden = NO;
    
    [self.tutorialTimer invalidate];
    
    [self.topScrollView setZoomScale:1.1 animated:NO];
    
//    [self centerScrollView:self.topScrollView];
}

- (void)zoomAnimationOnFace
{
    if (self.topScrollView.zoomScale < 1.2) {
        [self.topScrollView setZoomScale:1.3 animated:YES];
    } else {
        [self.topScrollView setZoomScale:1.1 animated:YES];
    }
}


- (IBAction)secondImageExposureSliderChanged:(id)sender {
    [self updateExposureForImage:2];
}
- (IBAction)firstImageExposureSliderChanged:(id)sender {
    [self updateExposureForImage:1];
}

- (IBAction)imageBorderSliderChanged:(id)sender {
    if (self.blendIndex == 0) {
        self.firstBlendStartY = self.imageBorderSlider.value;
        [self firstBlend];
    } else {
        self.secondBlendStartY = self.imageBorderSlider.value;
        [self secondBlend];
    }
}

- (IBAction)fistFilterClicked:(id)sender {
    [self setFilterButtonBorder:self.firstFilterButton];
    
    self.filterIndex = 0;
    [self updateFilter];
}

- (IBAction)secondFilterClicked:(id)sender {
    [self setFilterButtonBorder:self.secondFilterButton];
    
    self.filterIndex = 1;
    [self updateFilter];
}

- (IBAction)thirdFilterClicked:(id)sender {
    [self setFilterButtonBorder:self.thirdFilterButton];
    
    self.filterIndex = 2;
    [self updateFilter];
}

- (IBAction)fourthFilterClicked:(id)sender {
    [self setFilterButtonBorder:self.fourthFilterButton];
    
    self.filterIndex = 3;
    [self updateFilter];
}

- (void)setFilterButtonBorder:(UIButton *)button
{
    [self.firstFilterButton.layer setBorderColor:0];
    [self.secondFilterButton.layer setBorderColor:0];
    [self.thirdFilterButton.layer setBorderColor:0];
    [self.fourthFilterButton.layer setBorderColor:0];
    
    [button.layer setBorderWidth:2.0];
    [button.layer setBorderColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0].CGColor];
}

@end
