//
//  DWMediaStore.h
//  DireFloof
//
//  Created by John Gabelmann on 3/6/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>

@interface DWMediaStore : NSObject

#pragma mark - Class Methods

+ (DWMediaStore *)sharedStore;


#pragma mark - Instance Methods

- (UIImage *)placeholderImage;
- (void)downloadGifvMedia:(NSURL *)mediaURL withCompletion:(void (^)(BOOL success, NSURL *localURL, NSError *error))completion;
- (NSURL *)cachedURLForGifvMedia:(NSURL *)mediaURL;

@end
