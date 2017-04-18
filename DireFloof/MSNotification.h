//
//  MSNotification.h
//  DireFloof
//
//  Created by John Gabelmann on 2/16/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import "MSAccount.h"
#import "MSStatus.h"

@interface MSNotification : NSObject

#pragma mark - Properties

@property (nonatomic, strong, readonly) NSString *_id;
@property (nonatomic, strong, readonly) NSString *type;
@property (nonatomic, strong, readonly) MSAccount *account;
@property (nonatomic, strong, readonly) MSStatus *status;


#pragma mark - Initializers

- (id)initWithParams:(NSDictionary *)params;

@end
