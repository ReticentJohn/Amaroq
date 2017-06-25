//
//  DWDraftStore.h
//  DireFloof
//
//  Created by John Gabelmann on 6/25/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>

@interface DWDraftStore : NSObject

#pragma mark - Class Methods

+ (DWDraftStore *)sharedStore;


#pragma mark - Instance Methods

- (NSString *)draftForPostId:(NSString *)postId;
- (void)setDraft:(NSString *)draftText forPostId:(NSString *)postId;

@end
