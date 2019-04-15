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
#import "DWProfileViewController.h"
#import "Mastodon.h"
#import "DWTimelineViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    if ([[MSAuthStore sharedStore] isLoggedIn]) {
        NSString *const host = url.host;
        if ([host isEqualToString:@"user"] && url.pathComponents.count > 1) {
            // amaroq://user/[fully qualified account name]
            // For example: amaroq://user/timonus@mastodon.technology
            NSString *const username = url.pathComponents[1]; // First path component is "/", second path component is the username.
            NSString *const sanitizedUsername = [username.lowercaseString stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"@"]];
            [[MSUserStore sharedStore] searchForUsersWithQuery:sanitizedUsername withCompletion:^(BOOL success, NSArray *users, NSError *error) {
                MSAccount *account = nil;
                for (MSAccount *candidateAccount in users) {
                    // We construct the username from the URL to ensure the host is present.
                    // For accounts on our same instance, acct won't contain the host.
                    NSString *const candidateFullUsername = [NSString stringWithFormat:@"%@@%@", candidateAccount.username, [NSURL URLWithString:candidateAccount.url].host];
                    NSString *const sanitizedCandidateUsername = candidateFullUsername.lowercaseString;
                    if ([sanitizedCandidateUsername isEqualToString:sanitizedUsername]) {
                        account = candidateAccount;
                        break;
                    }
                }
                if (account) {
                    DWProfileViewController *profileViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"ProfileViewController"];
                    profileViewController.account = account;
                    
                    UINavigationController *navController = [[self viewControllerForPerfomingDeepLinkSegues] navigationController];
                    
                    if (navController) {
                        [navController pushViewController:profileViewController animated:YES];
                    }
                }
            }];
        }
        else if ([host isEqualToString:@"open"]) {
            // amaroq://open?url=[URL to a Mastodon account or status]
            // For example:
            // amaroq://open?url=https%3A%2F%2Fmastodon.social%2F%40Gargron%2F101927228503810895
            // amaroq://open?url=https%3A%2F%2Ftoot.cafe%2F%40chartier
            NSURLComponents *const components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
            NSString *objectURLString = nil;
            for (NSURLQueryItem *const queryItem in components.queryItems) {
                if ([queryItem.name isEqual:@"url"]) {
                    objectURLString = queryItem.value;
                    break;
                }
            }
            
            if (objectURLString) {
                NSDictionary *params = @{@"q": objectURLString, @"resolve": @YES};
                
                [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:@"search" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    UIViewController *viewControllerToPresent = nil;
                    if (responseObject != nil) {
                        NSDictionary *const statusDictionary = [[responseObject objectForKey:@"statuses"] firstObject];
                        if (statusDictionary) {
                            MSStatus *const status = [[MSStatus alloc] initWithParams:statusDictionary];
                            DWTimelineViewController *threadViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"StatusViewController"];
                            threadViewController.threadStatus = status;
                            viewControllerToPresent = threadViewController;
                        } else {
                            NSDictionary *const accountDictionary = [[responseObject objectForKey:@"accounts"] firstObject];
                            if (accountDictionary) {
                                MSAccount *const account = [[MSAccount alloc] initWithParams:accountDictionary];
                                DWProfileViewController *profileViewController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"ProfileViewController"];
                                profileViewController.account = account;
                                viewControllerToPresent = profileViewController;
                            }
                        }
                    }
                    if (viewControllerToPresent) {
                        UINavigationController *navController = [[self viewControllerForPerfomingDeepLinkSegues] navigationController];
                        [navController pushViewController:viewControllerToPresent animated:YES];
                    }
                } failure:nil];
            }
        }
    }
    return YES;
}

- (UIViewController *)viewControllerForPerfomingDeepLinkSegues
{
    UIViewController *viewController = [[UIApplication sharedApplication] topController];
    while ([viewController isKindOfClass:[UITabBarController class]] || [viewController isKindOfClass:[UINavigationController class]]) {
        if ([viewController isKindOfClass:[UITabBarController class]]) {
            viewController = [(UITabBarController *)viewController selectedViewController];
        } else if ([viewController isKindOfClass:[UINavigationController class]]) {
            viewController = [(UINavigationController *)viewController topViewController];
        }
    }
    return viewController;
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
