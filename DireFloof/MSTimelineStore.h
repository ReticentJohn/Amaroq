//
//  MSTimelineStore.h
//  DireFloof
//
//  Created by John Gabelmann on 2/7/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import "MastodonConstants.h"
#import "MSTimeline.h"

@interface MSTimelineStore : NSObject

#pragma mark - Class Methods

+ (MSTimelineStore *)sharedStore;


#pragma mark - Instance Methods

- (void)getTimelineForTimelineType:(MSTimelineType)timelineType withCompletion:(void (^)(BOOL success, MSTimeline *timeline, NSError *error))completion;
- (void)getHashtagTimelineWithHashtag:(NSString *)hashtag withCompletion:(void (^)(BOOL success, MSTimeline *timeline, NSError *error))completion;
- (void)getStatusesForUserId:(NSString *)userId withCompletion:(void (^)(BOOL success, MSTimeline *statuses, NSError *error))completion;
- (void)getFavoriteStatusesWithCompletion:(void (^)(BOOL success, MSTimeline *favoriteStatuses, NSError *error))completion;
- (void)getThreadForStatus:(MSStatus *)status withCompletion:(void (^)(BOOL success, MSTimeline *statusThread, NSError *error))completion;

@end
