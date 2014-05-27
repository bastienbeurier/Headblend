//
//  IndexViewController.m
//  Headblend
//
//  Created by Bastien Beurier on 5/27/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#define PER_PAGE 20

#import "IndexViewController.h"
#import "ApiUtilities.h"
#import "BlendViewController.h"

@interface IndexViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) NSMutableArray *viewControllers;
@property (nonatomic, strong) NSMutableArray *blends;
@property (nonatomic) NSInteger page;
@property (nonatomic) BOOL noMoreBlendToPull;
@property (nonatomic) BOOL pullingMoreBlends;
@property (nonatomic) NSUInteger lastPageScrolled;
@property (weak, nonatomic) IBOutlet UIButton *refreshButton;
@property (weak, nonatomic) IBOutlet UILabel *errorMessage;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;

@end

@implementation IndexViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // a page is the width of the scroll view
    self.scrollView.pagingEnabled = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
    
    self.page = 1;
    self.noMoreBlendToPull = NO;
    self.pullingMoreBlends = NO;
    
    [self refreshBlends];
}

- (UIStatusBarStyle) preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)refreshBlends
{
    self.page = 1;
    [self gotoPage:0 animated:NO];

    
    [self loadingBlendsUI];
    
    [ApiUtilities pullBlendsPage:1 pageSize:PER_PAGE AndExecuteSuccess:^(NSArray *blends, NSInteger page) {
        self.blends = [blends mutableCopy];
    } failure:^{
        [self noConnectionUI];
    }];
}

- (void)showLoadingIndicator
{
    if (!self.activityView) {
        self.activityView=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.activityView.center=self.view.center;
    }
    
    [self.activityView startAnimating];
    [self.view addSubview:self.activityView];
}

- (void)hideLoadingIndicator
{
    [self.activityView stopAnimating];
    [self.activityView removeFromSuperview];
}

- (void)loadingBlendsUI
{
    [self showLoadingIndicator];
    self.refreshButton.hidden = YES;
    self.errorMessage.hidden = YES;
    self.scrollView.hidden = YES;
}

- (void)noConnectionUI
{
    [self hideLoadingIndicator];
    self.refreshButton.hidden = NO;
    self.errorMessage.text = @"No connection. Please refresh.";
    self.errorMessage.hidden = NO;
    self.scrollView.hidden = YES;
}

- (void)displayBlendsUI
{
    [self hideLoadingIndicator];
    self.refreshButton.hidden = YES;
    self.errorMessage.hidden = YES;
    self.scrollView.hidden = NO;
}

- (void)onBlendCreated
{
    [self refreshBlends];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    NSUInteger page = [self getScrollViewPage];
    
    //Skip if method already called for this page or if scrolling automatically (when user clicks on marker)
    if (page == self.lastPageScrolled) {
        return;
    }
    
    self.lastPageScrolled = page;
    
    if (page > [self.viewControllers count] - 1) {
        return;
    }
    
    [self loadBlendsInFeed];
    
    //Pull more blends if it's the last blend
    if (page >= self.blends.count - 5 && !self.noMoreBlendToPull && !self.pullingMoreBlends) {
        
        self.pullingMoreBlends = YES;
        
        [ApiUtilities pullBlendsPage:self.page + 1 pageSize:PER_PAGE AndExecuteSuccess:^(NSArray *blends, NSInteger page) {
            self.pullingMoreBlends = NO;
            
            if (page == self.page + 1) {
                self.page = self.page + 1;
                
                self.blends = [[self.blends arrayByAddingObjectsFromArray:blends] mutableCopy];
                
                [self setBlends:self.blends];
            }

        } failure:^{
            self.pullingMoreBlends = NO;
        }];
    }
}

- (void)gotoPage:(NSUInteger)page animated:(BOOL)animated
{
    // update the scroll view to the appropriate page
    CGRect bounds = self.scrollView.bounds;
    bounds.origin.x = 0;
    bounds.origin.y = CGRectGetHeight(bounds) * page;
    
    [self.scrollView scrollRectToVisible:bounds animated:animated];
}

- (NSUInteger)getScrollViewPage
{
    // switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageHeight = self.scrollView.frame.size.height;
    return floor((self.scrollView.contentOffset.y - pageHeight / 2) / pageHeight) + 1;
}

- (void)loadScrollViewWithPage:(NSUInteger)page
{
    if (page >= self.blends.count) {
        return;
    }
    
    // replace the placeholder if necessary
    BlendViewController *controller = [self.viewControllers objectAtIndex:page];
    if ((NSNull *)controller == [NSNull null])
    {
        controller = [[BlendViewController alloc] initWithBlend:[self.blends objectAtIndex:page]];
        [self.viewControllers replaceObjectAtIndex:page withObject:controller];
    }
    
    // add the controller's view to the scroll view
    if (controller.view.superview == nil) {
        controller.view.frame = CGRectMake(0, self.scrollView.frame.size.height * page, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
        
        [self addChildViewController:controller];
        [self.scrollView addSubview:controller.view];
        [controller didMoveToParentViewController:self];
    }
}

- (void)unloadScrollViewWithPage:(NSUInteger)page
{
    if (page >= self.blends.count) {
        return;
    }
    
    // replace the placeholder if necessary
    BlendViewController *controller = [self.viewControllers objectAtIndex:page];
    
    if ((NSNull *)controller != [NSNull null]) {
        [[self.viewControllers objectAtIndex:page] removeFromParentViewController];
        [((BlendViewController *)[self.viewControllers objectAtIndex:page]).view removeFromSuperview];
        [self.viewControllers replaceObjectAtIndex:page withObject:[NSNull null]];
    }
}

- (void)loadBlendsInFeed
{
    NSInteger page = [self getScrollViewPage];
    
    if (page > [self.blends count] - 1) {
        return;
    }
    
    NSUInteger count = [self.viewControllers count];
    
    for (int i = 0; i < count; i = i + 1) {
        if (i >= MAX(page - 2, 0) && i <= page + 2) {
            [self loadScrollViewWithPage:i];
        } else {
            [self unloadScrollViewWithPage:i];
        }
    }
}

- (void)setBlends:(NSMutableArray *)blends
{
    _blends = blends;
    
    self.noMoreBlendToPull = NO;
    self.pullingMoreBlends = NO;
    
    if ([blends count] < PER_PAGE * self.page) {
        self.noMoreBlendToPull = YES;
    }
    
    if ([blends count] == 0) {
        return;
    }
    
    //Remove existing controllers
    if (self.viewControllers) {
        NSUInteger count = [self.viewControllers count];
        
        for (NSUInteger i = 0; i < count; i++) {
            BlendViewController *viewController = [self.viewControllers objectAtIndex:i];
            if ((NSNull *)viewController != [NSNull null]) {
                [viewController removeFromParentViewController];
                [viewController.view removeFromSuperview];
                viewController = (BlendViewController *)[NSNull null];
            }
        }
    }
    
    NSUInteger numberPages = self.blends.count;
    
    // view controllers are created lazily
    // in the meantime, load the array with placeholders which will be replaced on demand
    NSMutableArray *controllers = [[NSMutableArray alloc] init];
    
    for (NSUInteger i = 0; i < numberPages; i++) {
        [controllers addObject:[NSNull null]];
    }
    
    self.viewControllers = controllers;
    
    if (self.noMoreBlendToPull) {
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.scrollView.frame.size.height * (numberPages + 1));
    } else {
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.scrollView.frame.size.height * numberPages);
    }
    
    [self displayBlendsUI];
    
    [self loadBlendsInFeed];
}

- (IBAction)refreshButtonClicked:(id)sender {
    [self refreshBlends];
}

@end
