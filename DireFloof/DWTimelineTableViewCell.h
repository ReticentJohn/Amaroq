//
//  DWTimelineTableViewCell.h
//  DireFloof
//
//  Created by John Gabelmann on 2/15/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>
#import "Mastodon.h"

@class DWTimelineTableViewCell;
@protocol DWTimelineTableViewCellDelegate <NSObject>

- (void)timelineCell:(DWTimelineTableViewCell *)cell didDeleteStatus:(MSStatus *)status;
- (void)timelineCell:(DWTimelineTableViewCell *)cell didBlockUser:(MSAccount *)user;
- (void)timelineCell:(DWTimelineTableViewCell *)cell didReportStatus:(MSStatus *)status;
- (void)timelineCell:(DWTimelineTableViewCell *)cell didMentionUser:(NSString *)user;
- (void)timelineCell:(DWTimelineTableViewCell *)cell didSelectUser:(NSString *)user;
- (void)timelineCell:(DWTimelineTableViewCell *)cell didSelectURL:(NSURL *)url;

@end

@interface DWTimelineTableViewCell : UITableViewCell

@property (nonatomic, weak) MSStatus *status;
@property (nonatomic, weak) MSNotification *notification;
@property (nonatomic, weak) id <DWTimelineTableViewCellDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL isThreadStatus;

@end
