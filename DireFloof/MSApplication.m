//
//  MSApplication.m
//  DireFloof
//
//  Created by John Gabelmann on 2/12/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "MSApplication.h"
#import "NSDictionary+Sanitation.h"

@interface MSApplication ()

@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *website;

@end

@implementation MSApplication

#pragma mark - Initializers

- (id)initWithParams:(NSDictionary *)params
{
    self = [super init];
    
    if (self) {
        
        params = [params removeNullValues];
        
        self.name = [params objectForKey:@"name"];
        self.website = [params objectForKey:@"website"];
    }
    
    return self;
}


#pragma mark - Instance Methods

- (NSDictionary *)toJSON
{
    NSMutableDictionary *params = [@{} mutableCopy];
    
    if (self.name) {
        [params setObject:self.name forKey:@"name"];
    }
    
    if (self.website) {
        [params setObject:self.website forKey:@"website"];
    }
    
    return params;
}

@end
