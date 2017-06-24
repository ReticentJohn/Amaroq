//
//  DWSettingStore.h
//  DireFloof
//
//  Created by John Gabelmann on 3/8/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>

@interface DWSettingStore : NSObject

#pragma mark - Properties

@property (nonatomic, assign) BOOL alwaysPrivate;
@property (nonatomic, assign) BOOL alwaysPublic;
@property (nonatomic, assign) BOOL awooMode;
@property (nonatomic, assign) BOOL disableGifPlayback;
@property (nonatomic, assign) BOOL newFollowerNotifications;
@property (nonatomic, assign) BOOL favoriteNotifications;
@property (nonatomic, assign) BOOL mentionNotifications;
@property (nonatomic, assign) BOOL boostNotifications;
@property (nonatomic, assign) BOOL showLocalTimeline;


#pragma mark - Class Methods

+ (DWSettingStore *)sharedStore;


#pragma mark - Instance Methods

- (NSString *)cacheSizeString;
- (void)purgeCaches;
- (void)performSettingMaintenance;

@end
