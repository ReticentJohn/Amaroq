//
//  MSStatusStore.h
//  DireFloof
//
//  Created by John Gabelmann on 2/8/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import "MastodonConstants.h"
#import "MSTimeline.h"
#import "MSStatus.h"

@interface MSStatusStore : NSObject

#pragma mark - Class Methods

+ (MSStatusStore *)sharedStore;


#pragma mark - Instance Methods

- (void)postStatusWithText:(NSString *)status inReplyToId:(NSString *)statusId withMedia:(NSArray *)media isSensitive:(BOOL)sensitive withVisibility:(NSString *)visibilityType andSpoilerText:(NSString *)spoilerText withProgress:(void (^)(CGFloat progress))progress withCompletion:(void (^)(BOOL success, NSDictionary *status, NSError *error))completion;
- (void)deleteStatusWithId:(NSString *)statusId withCompletion:(void (^)(BOOL success, NSError *error))completion;
- (void)reblogStatusWithId:(NSString *)statusId withCompletion:(void (^)(BOOL success, NSError *error))completion;
- (void)unreblogStatusWithId:(NSString *)statusId withCompletion:(void (^)(BOOL success, NSError *error))completion;
- (void)favoriteStatusWithId:(NSString *)statusId withCompletion:(void (^)(BOOL success, NSError *error))completion;
- (void)unfavoriteStatusWithId:(NSString *)statusId withCompletion:(void (^)(BOOL success, NSError *error))completion;
- (void)reportStatus:(MSStatus *)status withComments:(NSString *)comments withCompletion:(void (^)(BOOL success, NSError *error))completion;
@end
