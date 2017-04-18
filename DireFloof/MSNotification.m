//
//  MSNotification.m
//  DireFloof
//
//  Created by John Gabelmann on 2/16/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "MSNotification.h"
#import "NSDictionary+Sanitation.h"

@interface MSNotification ()

@property (nonatomic, strong, readwrite) NSString *_id;
@property (nonatomic, strong, readwrite) NSString *type;
@property (nonatomic, strong, readwrite) MSAccount *account;
@property (nonatomic, strong, readwrite) MSStatus *status;

@end

@implementation MSNotification

#pragma mark - Initializers

- (id)initWithParams:(NSDictionary *)params
{
    self = [super init];
    
    if (self) {
        
        params = [params removeNullValues];
        
        self._id = [params objectForKey:@"id"];
        self.type = [params objectForKey:@"type"];
        self.account = [[MSAccount alloc] initWithParams:[params objectForKey:@"account"]];
        self.status = [params objectForKey:@"status"] ? [[MSStatus alloc] initWithParams:[params objectForKey:@"status"]] : nil;
    }
    
    return self;
}

@end
