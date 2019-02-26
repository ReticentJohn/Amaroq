//
//  AppDelegate.m
//  DireFloof
//
//  Created by John Gabelmann on 2/4/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <AFNetworking/AFNetworking.h>
#import "AppDelegate.h"
#import "DWAppearanceProxies.h"
#import "DWNotificationStore.h"
#import "DWConstants.h"
#import "UIApplication+TopController.h"
#import "DWLoginViewController.h"
#import "DWSettingStore.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    return YES;
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [DWAppearanceProxies configureAppearanceProxies];
    [[DWSettingStore sharedStore] performSettingMaintenance];
    
    // Kicks the notification store to initialize the notification delegate on launch
    [DWNotificationStore sharedStore];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [[NSNotificationCenter defaultCenter] postNotificationName:DW_WILL_PURGE_CACHE_NOTIFICATION object:nil];
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [DWAppearanceProxies configureAppearanceProxies];
    
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
    [[DWNotificationStore sharedStore] registerForNotifications];
    
    // Kicks the login screen if we're resuming from suspension
    if ([[[UIApplication sharedApplication] topController] isKindOfClass:[DWLoginViewController class]]) {
        [[[UIApplication sharedApplication] topController] viewDidAppear:NO];
    }
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
}


- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    completionHandler(UIBackgroundFetchResultNoData);
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    [[MSNotificationStore sharedStore] subscribePushNotificationsWithDeviceToken:deviceToken withCompletion:^(BOOL success, NSError *error) {
        if (success) {
        }
        else {
        }
    }];
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    [DWNotificationStore sharedStore].notificationBadge.hidden = NO;

    completionHandler(UIBackgroundFetchResultNewData);
}


- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [DWNotificationStore sharedStore].notificationBadge.hidden = NO;
}

@end
