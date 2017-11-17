//
//  MSEmoji.h
//  DireFloof
//
//  Created by John Gabelmann on 11/16/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>

@interface MSEmoji : NSObject

#pragma mark - Properties

@property (nonatomic, strong, readonly) NSString *shortcode;
@property (nonatomic, strong, readonly) NSString *static_url;
@property (nonatomic, strong, readonly) NSString *url;


#pragma mark - Initializers

- (id)initWithParams:(NSDictionary *)params;


#pragma mark - Instance Methods

- (NSDictionary *)toJSON;

@end
