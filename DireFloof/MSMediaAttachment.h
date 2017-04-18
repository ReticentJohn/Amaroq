//
//  MSMediaAttachment.h
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

@interface MSMediaAttachment : NSObject

#pragma mark - Properties

@property (nonatomic, strong, readonly) NSString *url;
@property (nonatomic, strong, readonly) NSString *preview_url;
@property (nonatomic, strong, readonly) NSString *remote_url;
@property (nonatomic, assign, readonly) MSMediaType type;


#pragma mark - Initializers

- (id)initWithParams:(NSDictionary *)params;


#pragma mark - Instance Methods

- (NSDictionary *)toJSON;

@end
