//
//  MSTimeline.h
//  DireFloof
//
//  Created by John Gabelmann on 2/12/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import "MastodonConstants.h"
#import "MSStatus.h"
#import "MSAccount.h"

@interface MSTimeline : NSObject

#pragma mark - Properties

@property (nonatomic, strong, readonly) NSMutableArray *statuses;
@property (nonatomic, strong, readonly) NSString *nextPageUrl;


#pragma mark - Initializers

- (id)initWithStatuses:(NSArray *)statuses nextPageUrl:(NSString *)url;
- (id)initWithNotifications:(NSArray *)notifications nextPageUrl:(NSString *)url;


#pragma mark - Instance Methods

- (void)loadNextPageWithCompletion:(void (^)(BOOL success, NSError *error))completion;
- (void)purgeLocalStatus:(MSStatus *)deletedStatus;
- (void)purgeLocalStatusesByUser:(MSAccount *)blockedUser;
- (void)filterForNotificationSettings;

@end
