//
//  MSNotificationStore.h
//  DireFloof
//
//  Created by John Gabelmann on 2/8/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import "MSTimeline.h"

@class MSPushNotificationStore;

@interface MSNotificationStore : NSObject

#pragma mark - Class Methods

+ (MSNotificationStore *)sharedStore;


#pragma mark - Instance Methods

- (void)getNotificationsSinceId:(NSString *)notificationId withCompletion:(void (^)(BOOL success, MSTimeline *notifications, NSError *error))completion;
- (void)clearNotificationsWithCompletion:(void (^)(BOOL success, NSError *error))completion;
- (void)subscribePushNotificationsWithDeviceToken:(NSData *)deviceToken withCompletion:(void (^)(BOOL, NSError *))completion;
- (void)unsubscribePushNotifications;

@end
