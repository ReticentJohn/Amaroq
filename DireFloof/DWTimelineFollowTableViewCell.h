//
//  DWTimelineFollowTableViewCell.h
//  DireFloof
//
//  Created by John Gabelmann on 2/16/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>
#import "Mastodon.h"

@interface DWTimelineFollowTableViewCell : UITableViewCell

@property (nonatomic, weak) MSNotification *notification;
@property (nonatomic, weak) MSAccount *account;

@property (nonatomic, assign) BOOL showMuteStatus;
@property (nonatomic, assign) BOOL isRequest;

@end
