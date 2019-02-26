//
//  MSAuthStore.h
//  DireFloof
//
//  Created by John Gabelmann on 2/7/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import <AFOAuth2Manager/AFOAuth2Manager.h>

@interface MSAuthStore : NSObject

#pragma mark - Properties

@property (nonatomic, readonly) BOOL isLoggedIn;
@property (nonatomic, strong) AFOAuthCredential *credential;


#pragma mark - Class Methods

+ (MSAuthStore *)sharedStore;


#pragma mark - Instance Methods

- (void)login:(void (^)(BOOL success))completion;
- (void)requestEditProfile;
- (void)requestPreferences;
- (void)logout;
- (void)unregisterForRemoteNotifications;
- (void)logoutOfInstance:(NSString *)instance;
- (void)switchToInstance:(NSString *)instance withCompletion:(void (^)(BOOL success))completion;
- (void)requestAddInstanceAccount;
@end
