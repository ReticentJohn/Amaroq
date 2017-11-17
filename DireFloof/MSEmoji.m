//
//  MSEmoji.m
//  DireFloof
//
//  Created by John Gabelmann on 11/16/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "MSEmoji.h"
#import "NSDictionary+Sanitation.h"

@interface MSEmoji ()

@property (nonatomic, strong, readwrite) NSString *shortcode;
@property (nonatomic, strong, readwrite) NSString *static_url;
@property (nonatomic, strong, readwrite) NSString *url;

@end

@implementation MSEmoji

#pragma mark - Initializers

- (id)initWithParams:(NSDictionary *)params
{
    self = [self init];
    
    if (self) {
        
        params = [params removeNullValues];
        
        NSString *shortcode = [params objectForKey:@"shortcode"];
        
        if (shortcode.length) {
            self.shortcode = [NSString stringWithFormat:@":%@:", shortcode];
        }
        
        self.static_url = [params objectForKey:@"static_url"];
        self.url = [params objectForKey:@"url"];
    }
    
    return self;
}


#pragma mark - Instance Methods

- (NSDictionary *)toJSON
{
    NSMutableDictionary *params = [@{} mutableCopy];
    
    if (self.url) {
        [params setObject:self.url forKey:@"url"];
    }
    
    if (self.static_url) {
        [params setObject:self.static_url forKey:@"static_url"];
    }
    
    if (self.shortcode) {
        [params setObject:[self.shortcode stringByReplacingOccurrencesOfString:@":" withString:@""] forKey:@"shortcode"];
    }
    
    return params;
}

@end
