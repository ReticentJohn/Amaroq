//
//  DWTimelineViewController.h
//  DireFloof
//
//  Created by John Gabelmann on 2/26/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "DWTabItemViewController.h"
#import "Mastodon.h"

@interface DWTimelineViewController : DWTabItemViewController

#pragma mark - Properties

@property (nonatomic, strong) NSString *hashtag;
@property (nonatomic, assign) BOOL favorites;

@property (nonatomic, strong) MSStatus *threadStatus;


#pragma mark - Actions

- (IBAction)scrollToTop:(id)sender;

@end
