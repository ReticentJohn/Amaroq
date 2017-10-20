//
//  DWNotificationStore.m
//  DireFloof
//
//  Created by John Gabelmann on 3/7/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Firebase/Firebase.h>
#import <UserNotifications/UserNotifications.h>
#import "DWNotificationStore.h"
#import "Mastodon.h"
#import "DWConstants.h"


@interface DWNotificationStore () <UNUserNotificationCenterDelegate, FIRMessagingDelegate>
@property (nonatomic, strong) UNUserNotificationCenter *notificationCenter;
@property (nonatomic, assign) BOOL notificationsGranted;
@property (nonatomic, assign) BOOL fetchingNotifications;
@end

@implementation DWNotificationStore

#pragma mark - Class Methods

+ (DWNotificationStore *)sharedStore
{
    static DWNotificationStore *sharedStore = nil;
    static dispatch_once_t storeToken;
    dispatch_once(&storeToken, ^{
        
        sharedStore = [[DWNotificationStore alloc] init];
    });
    
    return sharedStore;
}


#pragma mark - Initializers

- (id)init
{
    self = [super init];
    
    if (self) {
        
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
        self.notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
        self.notificationCenter.delegate = self;
#endif
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenRefreshNotification:) name:kFIRInstanceIDTokenRefreshNotification object:nil];
    }
    
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Instance Methods

- (void)stopNotificationRefresh
{
    [[MSAuthStore sharedStore] unregisterForRemoteNotifications];
    [[UIApplication sharedApplication] unregisterForRemoteNotifications];
}


- (void)registerForNotifications
{
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
        UIUserNotificationType allNotificationTypes =
        (UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge);
        UIUserNotificationSettings *settings =
        [UIUserNotificationSettings settingsForTypes:allNotificationTypes categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    } else {
        // iOS 10 or later
#if defined(__IPHONE_10_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0
        [self.notificationCenter requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound completionHandler:^(BOOL granted, NSError * _Nullable error) {
            self.notificationsGranted = granted;
        }];
        
        // For iOS 10 data message (sent via FCM)
        [FIRMessaging messaging].delegate = self;
#endif
    }
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}


- (void)checkForNotificationsWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if (![[MSAuthStore sharedStore] isLoggedIn]) {
        // If we aren't logged in we're in an immediate failure
        if (completionHandler != nil) {
            completionHandler(UIBackgroundFetchResultFailed);
        }
        
        return;
    }
    
    NSString *sinceId = [[NSUserDefaults standardUserDefaults] objectForKey:MS_LAST_NOTIFICATION_ID_KEY];
    NSDate *lastBackgroundFetch = [[NSUserDefaults standardUserDefaults] objectForKey:MS_LAST_BACKGROUND_FETCH_KEY];
    
    if (!sinceId && self.notificationTimeline) {
        sinceId = [[self.notificationTimeline.statuses firstObject] _id];
    }
    
    if (lastBackgroundFetch) {
        if (self.fetchingNotifications && fabs([lastBackgroundFetch timeIntervalSinceNow]) > 60) {
            self.fetchingNotifications = NO;
        }
    }
    else
    {
        // This means we've attempted a background fetch before and failed
        self.fetchingNotifications = NO;
    }
    
    if (self.fetchingNotifications) {
        if (completionHandler != nil) {
            completionHandler(UIBackgroundFetchResultNoData);
        }
        
        return;
    }
    
    self.fetchingNotifications = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[MSNotificationStore sharedStore] getNotificationsSinceId:sinceId withCompletion:^(BOOL success, MSTimeline *notifications, NSError *error) {
            
            self.fetchingNotifications = NO;
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:MS_LAST_BACKGROUND_FETCH_KEY];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            if (success) {
                
                [notifications filterForNotificationSettings];
                
                if (notifications.statuses.count) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:DW_NEEDS_REFRESH_NOTIFICATION object:nil];

                        if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive && completionHandler != nil) {
                            [self queuePendingNotifications:notifications withCompletionHandler:completionHandler];
                        }
                        else if (self.notificationBadge)
                        {
                            if (completionHandler != nil) {
                                completionHandler(UIBackgroundFetchResultNewData);
                            }
                            self.notificationBadge.hidden = NO;
                        }
                    });
                }
                else
                {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        // No new notifications since last update, end here
                        if (completionHandler != nil) {
                            completionHandler(UIBackgroundFetchResultNoData);
                        }
                    });
                }
                
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Somethings gone wrong that we can't communicate so we're going to end here
                    if (completionHandler != nil) {
                        completionHandler(UIBackgroundFetchResultFailed);
                    }
                });
            }            
        }];
    });
}


#pragma mark - UNUserNotificationCenter Delegate Methods

// Handle incoming notification messages while app is in the foreground.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler
{
    // Print message ID.
    NSDictionary *userInfo = notification.request.content.userInfo;
    if (userInfo[kGCMMessageIDKey]) {
       // NSLog(@"Message ID: %@", userInfo[kGCMMessageIDKey]);
    }
    
    // Print full message.
    //NSLog(@"%@", userInfo);
    
    // Change this to your preferred presentation option
    completionHandler(UNNotificationPresentationOptionNone);
}

//Handle notification messages after display notification is tapped by the user.
- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler
{
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    if (userInfo[kGCMMessageIDKey]) {
        //NSLog(@"Message ID: %@", userInfo[kGCMMessageIDKey]);
    }
    
    // Print full message.
    //NSLog(@"%@", userInfo);
    
    completionHandler();
}


#pragma mark - FIRMessaging Delegate Methods

- (void)applicationReceivedRemoteMessage:(FIRMessagingRemoteMessage *)remoteMessage
{
    //NSLog(@"%@", remoteMessage.appData);
}


- (void)messaging:(nonnull FIRMessaging *)messaging didRefreshRegistrationToken:(nonnull NSString *)fcmToken
{
    [[MSAuthStore sharedStore] registerForRemoteNotificationsWithToken:fcmToken];
}



#pragma mark - Observers

- (void)tokenRefreshNotification:(NSNotification *)notification
{
    // Note that this callback will be fired everytime a new token is generated, including the first
    // time. So if you need to retrieve the token as soon as it is available this is where that
    // should be done.
    //NSLog(@"InstanceID token: %@", refreshedToken);
    
    // Connect to FCM since connection may have failed when attempted before having a token.
    [self connectToFcm];
    
    [[MSAuthStore sharedStore] registerForRemoteNotificationsWithToken:[[FIRInstanceID instanceID] token]];
}


#pragma mark - Private Methods

- (void)queuePendingNotifications:(MSTimeline *)notifications withCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSString *body = nil;
    NSString *title = nil;
    
    if (notifications.statuses.count > 1) {
        // Give a general notification since there's multiple
        body = [NSString stringWithFormat:@"%@ %li %@", NSLocalizedString(@"You have", @"You have"), (long)notifications.statuses.count, NSLocalizedString(@"new notifications", @"new notifications")];
    }
    else
    {
        // Personalized notification since there's only one
        MSNotification *notification = [notifications.statuses firstObject];
        
        title = notification.account.display_name.length ? notification.account.display_name : notification.account.username;
        
        if ([notification.type isEqualToString:MS_NOTIFICATION_TYPE_REBLOG]) {
            
            title = [title stringByAppendingString:[NSString stringWithFormat:@" %@", NSLocalizedString(@"boosted your status", @"boosted your status")]];
            
            if (notification.status.spoiler_text.length) {
                body = notification.status.spoiler_text;
            }
            else
            {
                body = notification.status.content;
            }
        }
        else if ([notification.type isEqualToString:MS_NOTIFICATION_TYPE_FAVORITE])
        {
            title = [title stringByAppendingString:[NSString stringWithFormat:@" %@", NSLocalizedString(@"favorited your status", @"favorited your status")]];
            if (notification.status.spoiler_text.length) {
                body = notification.status.spoiler_text;
            }
            else
            {
                body = notification.status.content;
            }
        }
        else if ([notification.type isEqualToString:MS_NOTIFICATION_TYPE_FOLLOW])
        {
            title = [title stringByAppendingString:[NSString stringWithFormat:@" %@", NSLocalizedString(@"followed you", @"followed you")]];
            body = @" ";
        }
        else
        {
            title = [title stringByAppendingString:[NSString stringWithFormat:@" %@", NSLocalizedString(@"mentioned you", @"mentioned you")]];
            
            if (notification.status.spoiler_text.length) {
                body = notification.status.spoiler_text;
            }
            else
            {
                body = notification.status.content;
            }
        }
    }
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + notifications.statuses.count;
        
        if (title) {
            localNotification.alertTitle = title;
        }
        
        if (body) {
            localNotification.alertBody = title;
        }
        
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
        if (completionHandler != nil) {
            completionHandler(UIBackgroundFetchResultNewData);
        }
    }
    else
    {
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        content.sound = [UNNotificationSound defaultSound];
        content.badge = @([UIApplication sharedApplication].applicationIconBadgeNumber + notifications.statuses.count);
        
        if (title) {
            content.title = title;
        }
        
        if (body) {
            content.body = body;
        }
        
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:DW_NOTIFICATIONS_AVAILABLE_IDENTIFIER content:content trigger:[UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.5 repeats:NO]];
        
        [self.notificationCenter addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            
            if (completionHandler != nil) {
                completionHandler(UIBackgroundFetchResultNewData);
            }
        }];
    }
}


- (void)connectToFcm
{
    // Won't connect since there is no token
    if (![[FIRInstanceID instanceID] token]) {
        return;
    }
    
    // Disconnect previous FCM connection if it exists.
    [[FIRMessaging messaging] setShouldEstablishDirectChannel:NO];
    [[FIRMessaging messaging] setShouldEstablishDirectChannel:YES];
}

@end
