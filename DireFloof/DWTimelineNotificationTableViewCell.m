//
//  DWTimelineNotificationTableViewCell.m
//  DireFloof
//
//  Created by John Gabelmann on 2/16/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "DWTimelineNotificationTableViewCell.h"
#import "DWConstants.h"

@interface DWTimelineNotificationTableViewCell ()

@property (nonatomic, weak) IBOutlet UIImageView *notificationTypeImageView;
@property (nonatomic, weak) IBOutlet UILabel *notificationAuthorLabel;
@property (nonatomic, weak) IBOutlet UILabel *notificationTypeLabel;

@end

@implementation DWTimelineNotificationTableViewCell

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

#pragma mark - Initialization

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if (self.notificationTypeImageView) {
        self.notificationTypeLabel.text = @"";
        self.notificationTypeLabel.text = @"";
        self.notificationTypeImageView.image = nil;
    }

    self.notificationTypeLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.notificationAuthorLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
}


- (void)prepareForReuse
{
    [super prepareForReuse];
    
    if (self.notificationTypeImageView) {
        self.notificationTypeLabel.text = @"";
        self.notificationTypeLabel.text = @"";
        self.notificationTypeImageView.image = nil;
    }
    
    self.notificationTypeLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.notificationAuthorLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
}


#pragma mark - Getter/Setter Methods

- (void)setNotification:(MSNotification *)notification
{
    [super setNotification:notification];
    
    [self configureNotificationContent];
}


- (void)setStatus:(MSStatus *)status
{
    [super setStatus:status];
    
    // If this is a simple reblog on the home or public page, go ahead with configuration
    if (!self.notification && self.notificationTypeImageView) {
        [self configureNotificationContent];
    }
}


#pragma mark - Private Methods

- (void)configureNotificationContent
{
    
    if (self.notification) {
        
        self.notificationAuthorLabel.text = self.notification.account.display_name.length ? self.notification.account.display_name : self.notification.account.username;
        
        if ([self.notification.type isEqualToString:MS_NOTIFICATION_TYPE_REBLOG]) {
            
            self.notificationTypeImageView.image = [UIImage imageNamed:@"RetootIcon"];
            self.notificationTypeImageView.tintColor = DW_BLUE_COLOR;
            self.notificationTypeLabel.text = NSLocalizedString(@"boosted your status", @"boosted your status");
        }
        else if ([self.notification.type isEqualToString:MS_NOTIFICATION_TYPE_FAVORITE])
        {
            self.notificationTypeImageView.image = [UIImage imageNamed:@"FavoriteIcon"];
            self.notificationTypeImageView.tintColor = DW_FAVORITED_ICON_TINT_COLOR;
            self.notificationTypeLabel.text = NSLocalizedString(@"favorited your status", @"favorited your status");
        }
    }
    else
    {
        if (self.status.reblog) {
            self.notificationAuthorLabel.text = self.status.account.display_name.length ? self.status.account.display_name : self.status.account.acct;
            self.notificationAuthorLabel.accessibilityLabel = [self.notificationAuthorLabel.text stringByAppendingFormat:@" %@", NSLocalizedString(@"boosted", @"boosted")];
            
            self.notificationTypeImageView.image = [UIImage imageNamed:@"RetootIcon"];
            self.notificationTypeImageView.tintColor = DW_BASE_ICON_TINT_COLOR;
            self.notificationTypeLabel.text = NSLocalizedString(@"boosted", @"boosted");
        }
        else
        {
            self.notificationAuthorLabel.text = self.status.account.display_name.length ? self.status.account.display_name : self.status.account.acct;
            
            self.notificationTypeImageView.image = [UIImage imageNamed:@"ReplyIcon"];
            self.notificationTypeImageView.tintColor = DW_BASE_ICON_TINT_COLOR;
            
            MSMention *mention = [self.status.mentions firstObject];
            
            if (self.status.in_reply_to_id && mention) {
                mention = [[self.status.mentions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"_id = %@", self.status.in_reply_to_account_id]] firstObject];
            }
            
            self.notificationTypeLabel.text = [NSString stringWithFormat:@"%@ %@", mention ? NSLocalizedString(@"replied to", @"replied to") : NSLocalizedString(@"replied", @"replied"), mention ? mention.acct : @""];
            self.notificationAuthorLabel.accessibilityLabel = [self.notificationAuthorLabel.text stringByAppendingFormat:@" %@", [NSString stringWithFormat:@"%@ %@", mention ? NSLocalizedString(@"replied to", @"replied to") : NSLocalizedString(@"replied", @"replied"), mention ? mention.acct : @""]];


        }
    }
}

@end
