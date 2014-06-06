//
//  MainAppDelegate.m
//  Headblend
//
//  Created by Bastien Beurier on 5/23/14.
//  Copyright (c) 2014 streetshout. All rights reserved.
//

#import "MainAppDelegate.h"
#import "DisplayViewController.h"
#import "CameraViewController.h"

@implementation MainAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if ([userDefaults objectForKey:@"INITIAL TUTO PREF"]) {
        self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        
        UIStoryboard *storyboard;
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            storyboard = [UIStoryboard storyboardWithName:@"Main_ipad" bundle:nil];
        } else {
            storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        }
        
        
        UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"CameraViewController"];
        
        self.window.rootViewController = viewController;
        [self.window makeKeyAndVisible];
    }
    
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
