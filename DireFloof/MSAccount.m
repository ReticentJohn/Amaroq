//
//  MSAccount.m
//  DireFloof
//
//  Created by John Gabelmann on 2/12/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <EmojiOne/Emojione.h>
#import "MSAccount.h"
#import "NSDictionary+Sanitation.h"
#import "NSString+HtmlStrip.h"
#import "MastodonConstants.h"

@interface MSAccount ()

@property (nonatomic, strong, readwrite) NSString *_id;
@property (nonatomic, strong, readwrite) NSString *username;
@property (nonatomic, strong, readwrite) NSString *acct;
@property (nonatomic, strong, readwrite) NSString *display_name;
@property (nonatomic, strong, readwrite) NSString *note;
@property (nonatomic, strong, readwrite) NSString *url;
@property (nonatomic, strong, readwrite) NSString *avatar;
@property (nonatomic, strong, readwrite) NSString *header;
@property (nonatomic, strong, readwrite) NSString *avatar_static;
@property (nonatomic, strong, readwrite) NSString *header_static;
@property (nonatomic, assign, readwrite) BOOL locked;
@property (nonatomic, strong, readwrite) NSNumber *followers_count;
@property (nonatomic, strong, readwrite) NSNumber *following_count;
@property (nonatomic, strong, readwrite) NSNumber *statuses_count;

@end

@implementation MSAccount

#pragma mark - Initializers

- (id)initWithParams:(NSDictionary *)params
{
    self = [super init];
    
    if (self) {
        
        params = [params removeNullValues];
        
        self._id = [[params objectForKey:@"id"] isKindOfClass:[NSNumber class]] ? [[params objectForKey:@"id"] stringValue] : [params objectForKey:@"id"];
        self.username = [params objectForKey:@"username"];
        self.acct = [params objectForKey:@"acct"];
        
        NSString *display_name = [params objectForKey:@"display_name"];
        
        if (display_name) {
            self.display_name = [Emojione shortnameToUnicode:display_name];
        }
        
        NSString *note = [params objectForKey:@"note"];
        
        if (note) {
            self.note = [note removeHTML];
        }
        
        self.url = [params objectForKey:@"url"];
        self.avatar = [[params objectForKey:@"avatar"] containsString:MS_MISSING_AVATAR_URL] ? [MS_BASE_URL_STRING stringByAppendingString:MS_MISSING_AVATAR_URL] : [params objectForKey:@"avatar"];
        self.avatar_static = [[params objectForKey:@"avatar_static"] containsString:MS_MISSING_AVATAR_URL] ? [MS_BASE_URL_STRING stringByAppendingString:MS_MISSING_AVATAR_URL] : [params objectForKey:@"avatar_static"];
        
        if (!self.avatar_static) {
            self.avatar_static = self.avatar;
        }
        
        self.header = [params objectForKey:@"header"];
        self.header_static = [params objectForKey:@"header_static"];
        
        if (!self.header_static) {
            self.header_static = self.header;
        }
        
        self.locked = [[params objectForKey:@"locked"] boolValue];
        self.followers_count = [params objectForKey:@"followers_count"];
        self.following_count = [params objectForKey:@"following_count"];
        self.statuses_count = [params objectForKey:@"statuses_count"];
    }
    
    return self;
}


#pragma mark - Instance Methods

- (NSDictionary *)toJSON
{
    NSMutableDictionary *params = [@{} mutableCopy];
    
    if (self._id) {
        [params setObject:self._id forKey:@"id"];
    }
    
    if (self.username) {
        [params setObject:self.username forKey:@"username"];
    }
    
    if (self.acct) {
        [params setObject:self.acct forKey:@"acct"];
    }
    
    if (self.display_name) {
        [params setObject:self.display_name forKey:@"display_name"];
    }
    
    if (self.note) {
        [params setObject:self.note forKey:@"note"];
    }
    
    if (self.url) {
        [params setObject:self.url forKey:@"url"];
    }
    
    if (self.avatar) {
        [params setObject:self.avatar forKey:@"avatar"];
    }
    
    if (self.avatar_static) {
        [params setObject:self.avatar_static forKey:@"avatar_static"];
    }
    
    if (self.header) {
        [params setObject:self.header forKey:@"header"];
    }
    
    if (self.header_static) {
        [params setObject:self.header_static forKey:@"header_static"];
    }
    
    [params setObject:@(self.locked) forKey:@"locked"];
    
    if (self.followers_count) {
        [params setObject:self.followers_count forKey:@"followers_count"];
    }
    
    if (self.following_count) {
        [params setObject:self.following_count forKey:@"following_count"];
    }
    
    if (self.statuses_count) {
        [params setObject:self.statuses_count forKey:@"statuses_count"];
    }
    
    return params;
}

@end
