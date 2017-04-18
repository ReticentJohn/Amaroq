//
//  MSAccount.h
//  DireFloof
//
//  Created by John Gabelmann on 2/12/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>

@interface MSAccount : NSObject

#pragma mark - Properties

@property (nonatomic, strong, readonly) NSString *_id;
@property (nonatomic, strong, readonly) NSString *username;
@property (nonatomic, strong, readonly) NSString *acct;
@property (nonatomic, strong, readonly) NSString *display_name;
@property (nonatomic, strong, readonly) NSString *note;
@property (nonatomic, strong, readonly) NSString *url;
@property (nonatomic, strong, readonly) NSString *avatar;
@property (nonatomic, strong, readonly) NSString *header;
@property (nonatomic, strong, readonly) NSString *avatar_static;
@property (nonatomic, strong, readonly) NSString *header_static;
@property (nonatomic, assign, readonly) BOOL locked;
@property (nonatomic, strong, readonly) NSNumber *followers_count;
@property (nonatomic, strong, readonly) NSNumber *following_count;
@property (nonatomic, strong, readonly) NSNumber *statuses_count;


#pragma mark - Initializers

- (id)initWithParams:(NSDictionary *)params;


#pragma mark - Instance Methods

- (NSDictionary *)toJSON;

@end
