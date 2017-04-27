//
//  MSAppStore.h
//  DireFloof
//
//  Created by John Gabelmann on 2/7/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>

@interface MSAppStore : NSObject

#pragma mark - Properties

@property (nonatomic, readonly) BOOL isRegistered;
@property (nonatomic, strong, readonly) NSString *client_id;
@property (nonatomic, strong, readonly) NSString *client_secret;
@property (nonatomic, strong, readonly) NSString *base_url_string;
@property (nonatomic, strong, readonly) NSString *base_api_url_string;
@property (nonatomic, strong, readonly) NSString *base_media_url_string;
@property (nonatomic, strong, readonly) NSString *instance;
@property (nonatomic, strong, readonly) NSArray *availableInstances;

#pragma mark - Class Methods

+ (MSAppStore *)sharedStore;


#pragma mark - Instance Methods

- (void)setMastodonInstance:(NSString *)instance;
- (void)removeMastodonInstance:(NSString *)instance;
- (void)registerApp:(void (^)(BOOL success))completion;

@end
