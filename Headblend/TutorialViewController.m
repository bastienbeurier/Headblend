//
//  TutorialPageViewController.m
//  Headblend
//
//  Created by Bastien Beurier on 6/6/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#define TUTORIAL_CONTROLLER_COUNT 4
#define IS_IPHONE_5 ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

#import "TutorialViewController.h"

@interface TutorialViewController ()

@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *quitButton;


@end

@implementation TutorialViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.scrollView.frame = self.view.frame;
    
    // a page is the width of the scroll view
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.delegate = self;
    
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * TUTORIAL_CONTROLLER_COUNT, self.scrollView.frame.size.height);
    
    for (int i = 0; i < TUTORIAL_CONTROLLER_COUNT; i = i + 1) {
        
        UIImageView *imageView;
        
        if (IS_IPHONE_5) {
            imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"tuto%u-h568.png", i + 1]]];
        } else {
            imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"tuto%u.png", i + 1]]];
        }
        
        imageView.frame = CGRectMake(self.scrollView.frame.size.width * i, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
        
        [self.scrollView addSubview:imageView];
    }
}

-(BOOL)prefersStatusBarHidden { return YES; }

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSUInteger page = [self getScrollViewPage];
    
    self.pageControl.currentPage = page;
    
    if (page == TUTORIAL_CONTROLLER_COUNT - 1) {
        self.quitButton.hidden = NO;
    } else {
        self.quitButton.hidden = YES;
    }
}

- (IBAction)quitButtonClicked:(id)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:@"dummy" forKey:@"INITIAL TUTO PREF"];
    [self quitTutorial];
}

- (NSUInteger)getScrollViewPage
{
    // switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.scrollView.frame.size.width;
    return floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
}

- (void)quitTutorial
{
    [self performSegueWithIdentifier:@"Camera Modal Segue" sender:nil];
}


@end
