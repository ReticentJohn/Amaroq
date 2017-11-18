//
//  MSMediaAttachment.m
//  DireFloof
//
//  Created by John Gabelmann on 2/12/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "MSMediaAttachment.h"
#import "NSDictionary+Sanitation.h"

@interface MSMediaAttachment ()

@property (nonatomic, strong, readwrite) NSString *url;
@property (nonatomic, strong, readwrite) NSString *preview_url;
@property (nonatomic, strong, readwrite) NSString *remote_url;
@property (nonatomic, strong, readwrite) NSString *_description;
@property (nonatomic, assign, readwrite) MSMediaType type;

@end

@implementation MSMediaAttachment

#pragma mark - Initializers

- (id)initWithParams:(NSDictionary *)params
{
    self = [super init];
    
    if (self) {
        
        params = [params removeNullValues];
        
        self.url = [params objectForKey:@"url"];
        
        self.preview_url = [params objectForKey:@"preview_url"];
        self.remote_url = [params objectForKey:@"remote_url"];
        self._description = [params objectForKey:@"description"];
        
        NSString *type = [params objectForKey:@"type"];
        
        self.type = [type isEqualToString:@"image"] ? MSMediaTypeImage : [type isEqualToString:@"gifv"] ? MSMediaTypeGifv : MSMediaTypeVideo;
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
    
    if (self.preview_url) {
        [params setObject:self.preview_url forKey:@"preview_url"];
    }
    
    if (self.remote_url) {
        [params setObject:self.remote_url forKey:@"remote_url"];
    }
    
    [params setObject:self.type == MSMediaTypeImage ? @"image" : self.type == MSMediaTypeGifv ? @"gifv" : @"video" forKey:@"type"];
        
    return params;
}


@end
