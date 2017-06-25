//
//  DWDraftStore.m
//  DireFloof
//
//  Created by John Gabelmann on 6/25/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "DWDraftStore.h"

#define kNewDraftKey @"DW_NEW_DRAFT_KEY"

@interface DWDraftStore ()
@property (nonatomic, strong) NSMutableDictionary *draftDict;
@end

@implementation DWDraftStore

#pragma mark - Class Methods

+ (DWDraftStore *)sharedStore
{
    static DWDraftStore *sharedStore = nil;
    static dispatch_once_t storeToken;
    dispatch_once(&storeToken, ^{
        
        sharedStore = [[DWDraftStore alloc] init];
    });
    
    return sharedStore;
}


#pragma mark - Initializers

- (id)init
{
    self = [super init];
    
    if (self) {
        
        self.draftDict = [@{} mutableCopy];
    }
    
    return self;
}


#pragma mark - Instance Methods

- (NSString *)draftForPostId:(NSString *)postId
{
    NSString *draftText = [self.draftDict objectForKey:postId ? postId : kNewDraftKey];
    
    if (draftText) {
        [self.draftDict removeObjectForKey:postId ? postId : kNewDraftKey];
    }
    
    return draftText;
}


- (void)setDraft:(NSString *)draftText forPostId:(NSString *)postId
{
    if (draftText.length) {
        
        [self.draftDict setObject:draftText forKey:postId ? postId : kNewDraftKey];
    }
}

@end
