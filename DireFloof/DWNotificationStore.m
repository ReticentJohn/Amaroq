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

#import <UserNotifications/UserNotifications.h>
#import "DWNotificationStore.h"
#import "Mastodon.h"
#import "DWConstants.h"


@interface DWNotificationStore () <UNUserNotificationCenterDelegate>
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
    
    self.notificationCenter = [UNUserNotificationCenter currentNotificationCenter];
    
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
}


- (void)registerForNotifications
{
    [self.notificationCenter requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionBadge | UNAuthorizationOptionSound completionHandler:^(BOOL granted, NSError * _Nullable error) {
        self.notificationsGranted = granted;
    }];
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

@end
