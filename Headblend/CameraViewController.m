//
//  HeadblendViewController.m
//  Headblend
//
//  Created by Bastien Beurier on 5/22/14.
//  Copyright (c) 2014 Headblend. All rights reserved.
//

#import "CameraViewController.h"
#import "ImageUtilities.h"
#import "Constants.h"
#import "DisplayViewController.h"
#import "PortraitImagePickerViewController.h"

@interface CameraViewController ()

@property (strong, nonatomic) PortraitImagePickerViewController * imagePickerController;
@property (strong, nonatomic) UIImagePickerController * libraryController;
@property (nonatomic) NSUInteger pictureIndex;
@property (strong, nonatomic) UIImageView *topImageView;
@property (strong, nonatomic) UIImageView *bottomImageView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;
@property (weak, nonatomic) IBOutlet UIImageView *faceTemplate;
@property (weak, nonatomic) IBOutlet UIButton *flipButton;
@property (weak, nonatomic) IBOutlet UIButton *libraryButton;

@end

@implementation CameraViewController {
    BOOL isOpening;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.sourceType = UIImagePickerControllerSourceTypeCamera;
    
	// Init and present full screen camera
    [self allocAndInitFullScreenCamera];
    
    self.pictureIndex = 0;
    
    [ImageUtilities outerGlow:self.flipButton];
    [ImageUtilities outerGlow:self.libraryButton];
    
    self.topImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    self.bottomImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    
    self.topImageView.contentMode = UIViewContentModeScaleAspectFill;
    self.bottomImageView.contentMode = UIViewContentModeScaleAspectFill;
    
    [self firstPictureMode];
    
    [self.imagePickerController.cameraOverlayView insertSubview:self.bottomImageView atIndex:0];
    
    isOpening = YES;
    self.backFromDisplay = NO;
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (isOpening || self.backFromDisplay) {
        [self presentCameraController];
        isOpening = NO;
        
        if (self.backFromDisplay) {
            self.backFromDisplay = NO;
            [self secondPictureMode];
        }
    }
}

- (void)firstPictureMode
{
    self.pictureIndex = 0;
    
    self.backButton.hidden = YES;
    self.captureButton.hidden = NO;
    
    self.faceTemplate.image = [UIImage imageNamed:@"camera-face1"];
    
    self.topImageView.image = nil;
    self.bottomImageView.image = nil;
    
    [ImageUtilities hideBottomHalf:self.topImageView offset:0];
    [ImageUtilities hideTopHalf:self.bottomImageView offset:0];
    
    self.bottomImageView.backgroundColor = [UIColor blackColor];
    
    self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
}

- (void)secondPictureMode
{
    self.pictureIndex = 1;
    
    self.backButton.hidden = NO;
    self.captureButton.hidden = NO;
    
    self.faceTemplate.image = [UIImage imageNamed:@"camera-face2"];
    
    self.bottomImageView.image = nil;
    [ImageUtilities hideBottomHalf:self.topImageView offset:0];
    [ImageUtilities hideTopHalf:self.bottomImageView offset:0];
    
    self.bottomImageView.backgroundColor = [UIColor clearColor];
}

// ----------------------------------------------------------
// Full screen Camera
// ----------------------------------------------------------

// Alloc the impage picker controller
- (void) allocAndInitFullScreenCamera
{
    // Create custom camera view
    PortraitImagePickerViewController *imagePickerController = [PortraitImagePickerViewController new];
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        return;
    }
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.delegate = self;
    
    if (self.sourceType == UIImagePickerControllerSourceTypeCamera) {
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        
        // Custom buttons
        imagePickerController.showsCameraControls = NO;
        imagePickerController.allowsEditing = NO;
        imagePickerController.navigationBarHidden=YES;
        
        NSString *xibName = @"CameraOverlayView";
        NSArray* nibViews = [[NSBundle mainBundle] loadNibNamed:xibName owner:self options:nil];
        UIView* myView = [ nibViews objectAtIndex: 0];
        myView.frame = self.view.frame;
        
        imagePickerController.cameraOverlayView = myView;
        
        // Transform camera to get full screen (for iphone 5)
        // ugly code
        if (self.view.frame.size.height == 568) {
            double translationFactor = (self.view.frame.size.height - kCameraHeight) / 2;
            CGAffineTransform translate = CGAffineTransformMakeTranslation(0.0, translationFactor);
            imagePickerController.cameraViewTransform = translate;
            
            double rescalingRatio = self.view.frame.size.height / kCameraHeight;
            CGAffineTransform scale = CGAffineTransformScale(translate, rescalingRatio, rescalingRatio);
            imagePickerController.cameraViewTransform = scale;
        }
        
        imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        
        
    } else {
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    }
    
    self.imagePickerController = imagePickerController;
    
    self.imagePickerController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

// Display the relevant part of the photo once taken
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)editInfo
{
    if (self.libraryController && self.imagePickerController) {
        [self dismissViewControllerAnimated:NO completion:^{
            [self presentCameraController];

        }];
        
        self.libraryController = nil;
    }
    
//    UIImage *image =  [ImageUtilities resizeImage:[editInfo objectForKey:UIImagePickerControllerOriginalImage]];
    UIImage *image =  [editInfo objectForKey:UIImagePickerControllerOriginalImage];
    UIImageOrientation orientation;
    double targetRatio = kScreenWidth / self.view.frame.size.height;
    
    if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        // Force portrait, and avoid mirror of front camera
        orientation = self.imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceFront ? UIImageOrientationLeftMirrored : UIImageOrientationRight;
    } else {
        orientation = UIImageOrientationRight;
    }
    
    if (self.pictureIndex == 0) {
        [self.imagePickerController.cameraOverlayView insertSubview:self.topImageView atIndex:1];
        if (self.view.frame.size.height == 568 && picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            self.topImageView.image = [ImageUtilities resizeImage:[ImageUtilities cropImage:image toFitWidthOnHeightTargetRatio:targetRatio andOrientate:orientation]];
        } else {
            if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
                self.topImageView.image = [ImageUtilities resizeImage:[UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:orientation]];
            } else {
                self.topImageView.image = [ImageUtilities resizeImage:image];
            }
        }
        
        [self secondPictureMode];
    } else {
        if (self.view.frame.size.height == 568 && picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
            self.bottomImageView.image = [ImageUtilities resizeImage:[ImageUtilities cropImage:image toFitWidthOnHeightTargetRatio:targetRatio andOrientate:orientation]];
        } else {
            if (picker.sourceType == UIImagePickerControllerSourceTypeCamera) {
                self.bottomImageView.image = [ImageUtilities resizeImage:[UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:orientation]];
            } else {
                self.bottomImageView.image = [ImageUtilities resizeImage:image];
            }
        }
        
        [self closeCamera];
        
        [self performSegueWithIdentifier:@"Share Modal Segue" sender:nil];
    }
    
    image = nil;
}

// --------------------------------
// Camera button clicked
// --------------------------------

- (IBAction)takePictureButtonClicked:(id)sender {
    [self.imagePickerController takePicture];
}

- (IBAction)cancelButtonClicked:(id)sender
{
    [self firstPictureMode];
}

- (void)closeCamera
{
    [self.imagePickerController dismissViewControllerAnimated:NO completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString * segueName = segue.identifier;
    
    if ([segueName isEqualToString: @"Share Modal Segue"]) {
        ((DisplayViewController *) [segue destinationViewController]).firstPersonImage = self.topImageView.image;
        ((DisplayViewController *) [segue destinationViewController]).secondPersonImage = self.bottomImageView.image;
        ((DisplayViewController *) [segue destinationViewController]).displayVCDelegate = self;
    }
}

- (IBAction)flipButtonClicked:(id)sender {
    if (self.imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceFront){
        self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceRear;
    } else {
        self.imagePickerController.cameraDevice = UIImagePickerControllerCameraDeviceFront;
    }
}

- (void)presentCameraController
{
    [self presentViewController:self.imagePickerController animated:NO completion:NULL];
}

- (IBAction)chooseLibraryImage:(id)sender {
    UIImagePickerController *imagePickerController = [UIImagePickerController new];
    if(![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        return;
    }
    
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.delegate = self;
    
    imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    self.libraryController = imagePickerController;
    
    self.libraryController.view.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    [self dismissViewControllerAnimated:NO completion:^{
        [self presentViewController:self.libraryController animated:NO completion:NULL];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    if (self.libraryController && self.imagePickerController) {
        [self dismissViewControllerAnimated:NO completion:^{
            [self presentCameraController];
        }];
        
        self.libraryController = nil;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationPortrait;
}

@end
