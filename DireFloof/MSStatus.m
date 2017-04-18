//
//  MSStatus.m
//  DireFloof
//
//  Created by John Gabelmann on 2/12/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <EmojiOne/Emojione.h>
#import <DateTools/DateTools.h>
#import "MSStatus.h"
#import "MSMediaAttachment.h"
#import "MSMention.h"
#import "NSDictionary+Sanitation.h"
#import "NSString+HtmlStrip.h"
#import "DWSettingStore.h"
#import "NSString+Awoo.h"
#import "DWConstants.h"

@interface MSStatus ()

@property (nonatomic, strong, readwrite) NSString *_id;
@property (nonatomic, strong, readwrite) NSString *uri;
@property (nonatomic, strong, readwrite) NSString *url;
@property (nonatomic, strong, readwrite) MSAccount *account;
@property (nonatomic, strong, readwrite) NSString *in_reply_to_id;
@property (nonatomic, strong, readwrite) NSString *in_reply_to_account_id;
@property (nonatomic, strong, readwrite) MSStatus *reblog;
@property (nonatomic, strong, readwrite) NSString *content;
@property (nonatomic, strong, readwrite) NSDate *created_at;
@property (nonatomic, strong, readwrite) NSNumber *reblogs_count;
@property (nonatomic, strong, readwrite) NSNumber *favourites_count;
@property (nonatomic, assign, readwrite) BOOL sensitive;
@property (nonatomic, strong, readwrite) NSString *spoiler_text;
@property (nonatomic, strong, readwrite) NSArray *media_attachments;
@property (nonatomic, strong, readwrite) NSArray *mentions;
@property (nonatomic, strong, readwrite) MSApplication *application;
@property (nonatomic, strong, readwrite) NSString *visibility;

@end

@implementation MSStatus

#pragma mark - Initializers

- (id)initWithParams:(NSDictionary *)params
{
    self = [self init];
    
    if (self) {
        
        params = [params removeNullValues];
        
        self._id = [params objectForKey:@"id"];
        self.uri = [params objectForKey:@"uri"];
        self.url = [params objectForKey:@"url"];
        self.account = [[MSAccount alloc] initWithParams:[params objectForKey:@"account"]];
        self.in_reply_to_id = [params objectForKey:@"in_reply_to_id"];
        self.in_reply_to_account_id = [params objectForKey:@"in_reply_to_account_id"];
        self.reblog = [params objectForKey:@"reblog"] ? [[MSStatus alloc] initWithParams:[params objectForKey:@"reblog"]] : nil;
        
        NSString *content = [params objectForKey:@"content"];
        NSNumber *cleansed = [params objectForKey:@"__cleansed"];
        
        if (content) {
            
            self.content = cleansed ? content : [content removeHTML];
            
            if ([[DWSettingStore sharedStore] awooMode]) {
                self.content = [self.content awooString];
            }
        }
        
        self.created_at = [params objectForKey:@"created_at"] ? [NSDate dateWithString:[params objectForKey:@"created_at"] formatString:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'" timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]] : nil;
        self.reblogs_count = [params objectForKey:@"reblogs_count"];
        self.favourites_count = [params objectForKey:@"favourites_count"];
        self.reblogged = [[params objectForKey:@"reblogged"] boolValue];
        self.favourited = [[params objectForKey:@"favourited"] boolValue];
        self.sensitive = [[params objectForKey:@"sensitive"] boolValue];
        
        NSString *spoiler_text = [params objectForKey:@"spoiler_text"];
        
        if (spoiler_text) {
            self.spoiler_text = [Emojione shortnameToUnicode:spoiler_text];
        }
        
        self.visibility = [params objectForKey:@"visibility"];
        
        NSArray *media_attachmentsJSON = [params objectForKey:@"media_attachments"];
        
        if (media_attachmentsJSON) {
            
            NSMutableArray *media_attachments = [@[] mutableCopy];
            
            for (NSDictionary *media_attachmentJSON in media_attachmentsJSON) {
                
                MSMediaAttachment *media_attachment = [[MSMediaAttachment alloc] initWithParams:media_attachmentJSON];
                [media_attachments addObject:media_attachment];
            }
            
            self.media_attachments = media_attachments;
        }
        
        NSArray *mentionsJSON = [params objectForKey:@"mentions"];
        
        if (mentionsJSON) {
            
            NSMutableArray *mentions = [@[] mutableCopy];
            
            for (NSDictionary *mentionJSON in mentionsJSON) {
                
                MSMention *mention = [[MSMention alloc] initWithParams:mentionJSON];
                [mentions addObject:mention];
            }
            
            self.mentions = mentions;
        }
        
        self.application = [params objectForKey:@"application"] ? [[MSApplication alloc] initWithParams:[params objectForKey:@"application"]] : nil;
        
    }
    
    return self;
}


- (id)init
{
    self = [super init];
    
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusFavorited:) name:DW_STATUS_FAVORITED_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusUnfavorited:) name:DW_STATUS_UNFAVORITED_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBoosted:) name:DW_STATUS_BOOSTED_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusUnboosted:) name:DW_STATUS_UNBOOSTED_NOTIFICATION object:nil];

    }
    
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Instance Methods

- (NSDictionary *)toJSON
{
    NSMutableDictionary *params = [@{} mutableCopy];
    
    if (self._id) {
        [params setObject:self._id forKey:@"id"];
    }
    
    if (self.uri) {
        [params setObject:self.uri forKey:@"uri"];
    }
    
    if (self.url) {
        [params setObject:self.url forKey:@"url"];
    }
    
    if (self.account) {
        [params setObject:[self.account toJSON] forKey:@"account"];
    }
    
    if (self.in_reply_to_id) {
        [params setObject:self.in_reply_to_id forKey:@"in_reply_to_id"];
    }
    
    if (self.in_reply_to_account_id) {
        [params setObject:self.in_reply_to_account_id forKey:@"in_reply_to_account_id"];
    }
    
    if (self.reblog) {
        [params setObject:[self.reblog toJSON] forKey:@"reblog"];
    }
    
    if (self.content) {
        [params setObject:self.content forKey:@"content"];
        [params setObject:@(YES) forKey:@"__cleansed"];
    }
    
    if (self.created_at) {
        [params setObject:[self.created_at formattedDateWithFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'" timeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]] forKey:@"created_at"];
    }
    
    if (self.reblogs_count) {
        [params setObject:self.reblogs_count forKey:@"reblogs_count"];
    }
    
    if (self.favourites_count) {
        [params setObject:self.favourites_count forKey:@"favourites_count"];
    }
    
    [params setObject:@(self.reblogged) forKey:@"reblogged"];
    [params setObject:@(self.favourited) forKey:@"favourited"];
    [params setObject:@(self.sensitive) forKey:@"sensitive"];
    
    if (self.spoiler_text) {
        [params setObject:self.spoiler_text forKey:@"spoiler_text"];
    }
    
    if (self.visibility) {
        [params setObject:self.visibility forKey:@"visibility"];
    }
    
    if (self.media_attachments) {
        
        NSMutableArray *mediaAttachmentsJSON = [@[] mutableCopy];
        
        for (MSMediaAttachment *mediaAttachment in self.media_attachments) {
            [mediaAttachmentsJSON addObject:[mediaAttachment toJSON]];
        }
        
        [params setObject:mediaAttachmentsJSON forKey:@"media_attachments"];
    }
    
    if (self.mentions) {
        NSMutableArray *mentionsJSON = [@[] mutableCopy];
        
        for (MSMention *mention in self.mentions) {
            [mentionsJSON addObject:[mention toJSON]];
        }
        
        [params setObject:mentionsJSON forKey:@"mentions"];
    }
    
    if (self.application) {
        [params setObject:[self.application toJSON] forKey:@"application"];
    }
    
    return params;
}


#pragma mark - Observers

- (void)statusFavorited:(NSNotification *)notification
{
    if ([self._id isEqual:notification.object]) {
        self.favourited = YES;
    }
}


- (void)statusUnfavorited:(NSNotification *)notification
{
    if ([self._id isEqual:notification.object]) {
        self.favourited = NO;
    }
}


- (void)statusBoosted:(NSNotification *)notification
{
    if ([self._id isEqual:notification.object]) {
        self.reblogged = YES;
    }
}


- (void)statusUnboosted:(NSNotification *)notification
{
    if ([self._id isEqual:notification.object]) {
        self.reblogged = NO;
    }
}

@end
