//
//  NSDictionary+Sanitation.m
//  DireFloof
//
//  Created by John Gabelmann on 2/13/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "NSDictionary+Sanitation.h"

@implementation NSDictionary (Sanitation)

- (NSDictionary *)removeNullValues
{
    NSMutableDictionary *dict = [self mutableCopy];
    NSArray *keysWithNullValues = [dict allKeysForObject:[NSNull null]];
    [dict removeObjectsForKeys:keysWithNullValues];
    
    return dict;
}

@end
