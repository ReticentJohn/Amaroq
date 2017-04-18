//
//  MSUserStore.h
//  DireFloof
//
//  Created by John Gabelmann on 2/11/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import "MSAccount.h"

@interface MSUserStore : NSObject

#pragma mark - Properties

@property (nonatomic, strong) MSAccount *currentUser;


#pragma mark - Class Methods

+ (MSUserStore *)sharedStore;
+ (void)loadNextPage:(NSString *)nextPageUrl withCompletion:(void (^)(NSArray *users, NSString *nextPageUrl, NSError *error))completion;

#pragma mark - Instance Methods

- (NSString *)currentAccountString;
- (void)getCurrentUserWithCompletion:(void (^)(BOOL success, MSAccount *user, NSError *error))completion;

- (void)getUserWithId:(NSString *)userId withCompletion:(void (^)(BOOL success, MSAccount *user, NSError *error))completion;
- (void)getFollowersForUserWithId:(NSString *)userId withCompletion:(void (^)(BOOL success, NSArray *followers, NSString *nextPageUrl, NSError *error))completion;
- (void)getFollowingForUserWithId:(NSString *)userId withCompletion:(void (^)(BOOL success, NSArray *following, NSString *nextPageUrl, NSError *error))completion;
- (void)getBlockedUsersWithCompletion:(void (^)(BOOL success, NSArray *blockedUsers, NSString *nextPageUrl, NSError *error))completion;
- (void)getRelationshipsToUsers:(NSArray *)userIds withCompletion:(void (^)(BOOL success, NSDictionary *relationships, NSError *error))completion;
- (void)searchForUsersWithQuery:(NSString *)query withCompletion:(void (^)(BOOL success, NSArray *users, NSError *error))completion;
- (void)getUsersWhoRebloggedStatusWithId:(NSString *)statusId withCompletion:(void (^)(BOOL success, NSArray *users, NSError *error))completion;
- (void)getUsersWhoFavoritedStatusWithId:(NSString *)statusId withCompletion:(void (^)(BOOL success, NSArray *users, NSError *error))completion;
- (void)followUserWithId:(NSString *)userId withCompletion:(void (^)(BOOL success, NSError *error))completion;
- (void)unfollowUserWithId:(NSString *)userId withCompletion:(void (^)(BOOL success, NSError *error))completion;
- (void)blockUserWithId:(NSString *)userId withCompletion:(void (^)(BOOL success, NSError *error))completion;
- (void)unblockUserWithId:(NSString *)userId withCompletion:(void (^)(BOOL success, NSError *error))completion;
- (void)muteUserWithId:(NSString *)userId withCompletion:(void (^)(BOOL success, NSError *error))completion;
- (void)unmuteUserWithId:(NSString *)userId withCompletion:(void (^)(BOOL success, NSError *error))completion;
- (void)getRemoteUserWithLongformUsername:(NSString *)username withCompletion:(void (^)(BOOL success, MSAccount *localUser, NSError *error))completion;

- (void)getMutedUsersWithCompletion:(void (^)(BOOL success, NSArray *blockedUsers, NSString *nextPageUrl, NSError *error))completion;

- (void)getFollowRequestUsersWithCompletion:(void (^)(BOOL success, NSArray *requests, NSString *nextPageUrl, NSError *error))completion;
- (void)authorizeFollowRequestWithId:(NSString *)userId withCompletion:(void (^)(BOOL success, NSError *error))completion;
- (void)rejectFollowRequestWithId:(NSString *)userId withCompletion:(void (^)(BOOL success, NSError *error))completion;

@end
