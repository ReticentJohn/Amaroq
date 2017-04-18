//
//  DWNotificationStore.h
//  DireFloof
//
//  Created by John Gabelmann on 3/7/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import "Mastodon.h"

#define kGCMMessageIDKey @"gcm.message_id"

@interface DWNotificationStore : NSObject

@property (nonatomic, strong) MSTimeline *notificationTimeline;
@property (nonatomic, weak) UIView *notificationBadge;


#pragma mark - Class Methods

+ (DWNotificationStore *)sharedStore;


#pragma mark - Instance Methods

- (void)stopNotificationRefresh;
- (void)registerForNotifications;
- (void)checkForNotificationsWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
- (void)connectToFcm;

@end
