//
//  AppDelegate.m
//  Crateless
//
//  Created by Ryan Nystrom on 8/5/12.
//  Copyright (c) 2012 Ryan Nystrom. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

#pragma mark - App delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [application setApplicationIconBadgeNumber:0];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [application setApplicationIconBadgeNumber:0];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [application setApplicationIconBadgeNumber:0];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [application setApplicationIconBadgeNumber:0];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    [notification setApplicationIconBadgeNumber:0];
    [application setApplicationIconBadgeNumber:0];
    
    NSString *cancelButton = [notification alertAction];
    NSString *message = [notification alertBody];
    
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:@"Crateless" message:message delegate:nil cancelButtonTitle:cancelButton otherButtonTitles:nil];
    [av show];
}

@end
