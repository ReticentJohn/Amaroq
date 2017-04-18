//
//  MSStatus.h
//  DireFloof
//
//  Created by John Gabelmann on 2/12/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import "MSAccount.h"
#import "MSApplication.h"

@interface MSStatus : NSObject

#pragma mark - Properties

@property (nonatomic, strong, readonly) NSString *_id;
@property (nonatomic, strong, readonly) NSString *uri;
@property (nonatomic, strong, readonly) NSString *url;
@property (nonatomic, strong, readonly) MSAccount *account;
@property (nonatomic, strong, readonly) NSString *in_reply_to_id;
@property (nonatomic, strong, readonly) NSString *in_reply_to_account_id;
@property (nonatomic, strong, readonly) MSStatus *reblog;
@property (nonatomic, strong, readonly) NSString *content;
@property (nonatomic, strong, readonly) NSDate *created_at;
@property (nonatomic, strong, readonly) NSNumber *reblogs_count;
@property (nonatomic, strong, readonly) NSNumber *favourites_count;
@property (nonatomic, assign) BOOL reblogged;
@property (nonatomic, assign) BOOL favourited;
@property (nonatomic, assign, readonly) BOOL sensitive;
@property (nonatomic, strong, readonly) NSString *spoiler_text;
@property (nonatomic, strong, readonly) NSString *visibility;
@property (nonatomic, strong, readonly) NSArray *media_attachments;
@property (nonatomic, strong, readonly) NSArray *mentions;
@property (nonatomic, strong, readonly) MSApplication *application;


#pragma mark - Initializers

- (id)initWithParams:(NSDictionary *)params;


#pragma mark - Instance Methods

- (NSDictionary *)toJSON;

@end
