//
//  DWTimelineTableViewCell.m
//  DireFloof
//
//  Created by John Gabelmann on 2/15/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <twitter-text/TwitterText.h>
#import <TTTAttributedLabel/TTTAttributedLabel.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <DateTools/DateTools.h>
#import "DWTimelineTableViewCell.h"
#import "DWConstants.h"
#import "UIApplication+TopController.h"
#import "DWTimelineViewController.h"
#import "DWNavigationViewController.h"
#import "DWSettingStore.h"

@interface DWTimelineTableViewCell () <TTTAttributedLabelDelegate>

@property (nonatomic, weak) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, weak) IBOutlet UILabel *displayLabel;
@property (nonatomic, weak) IBOutlet UILabel *usernameLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet TTTAttributedLabel *contentLabel;
@property (nonatomic, weak) IBOutlet UIButton *retootButton;
@property (nonatomic, weak) IBOutlet UIButton *favoriteButton;
@property (nonatomic, weak) IBOutlet UIButton *warningTagButton;
@property (nonatomic, weak) IBOutlet UIVisualEffectView *warningTagView;
@property (nonatomic, weak) IBOutlet UILabel *warningTagLabel;
@property (nonatomic, weak) IBOutlet UILabel *retootCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *favoriteCountLabel;
@property (nonatomic, weak) IBOutlet UIImageView *retootCountImage;
@property (nonatomic, weak) IBOutlet UIImageView *favoriteCountImage;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *warningTagTopLabelConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *warningTagTopMediaConstraint;
@property (nonatomic, assign, readwrite) BOOL isThreadStatus;

@property (nonatomic, strong) UILongPressGestureRecognizer *contentWarningGestureRecognizer;

@end

@implementation DWTimelineTableViewCell

#pragma mark - Actions

- (IBAction)avatarButtonPressed:(id)sender
{
    
}


- (IBAction)retootButtonPressed:(id)sender
{
    __block MSStatus *status = self.status.reblog ? self.status.reblog : self.status;

    if (status.reblogged) {
        
        self.retootButton.tintColor = DW_BASE_ICON_TINT_COLOR;
        [[MSStatusStore sharedStore] unreblogStatusWithId:status._id withCompletion:^(BOOL success, NSError *error) {
            if (success) {
                status.reblogged = NO;
                self.retootButton.tintColor = DW_BASE_ICON_TINT_COLOR;
                [[NSNotificationCenter defaultCenter] postNotificationName:DW_STATUS_UNBOOSTED_NOTIFICATION object:status._id];
            }
        }];
    }
    else
    {
        self.retootButton.tintColor = DW_BLUE_COLOR;
        [[MSStatusStore sharedStore] reblogStatusWithId:status._id withCompletion:^(BOOL success, NSError *error) {
            if (success) {
                status.reblogged = YES;
                self.retootButton.tintColor = DW_BLUE_COLOR;
                [[NSNotificationCenter defaultCenter] postNotificationName:DW_STATUS_BOOSTED_NOTIFICATION object:status._id];
            }
        }];
    }
}


- (IBAction)replyButtonPressed:(id)sender
{

}


- (IBAction)favoriteButtonPressed:(id)sender
{
    __block MSStatus *status = self.status.reblog ? self.status.reblog : self.status;
    
    if (status.favourited) {
        
        self.favoriteButton.tintColor = DW_BASE_ICON_TINT_COLOR;
        [[MSStatusStore sharedStore] unfavoriteStatusWithId:status._id withCompletion:^(BOOL success, NSError *error) {
            if (success) {
                status.favourited = NO;
                self.favoriteButton.tintColor = DW_BASE_ICON_TINT_COLOR;
                [[NSNotificationCenter defaultCenter] postNotificationName:DW_STATUS_UNFAVORITED_NOTIFICATION object:status._id];
            }
        }];
    }
    else
    {
        self.favoriteButton.tintColor = DW_FAVORITED_ICON_TINT_COLOR;
        [[MSStatusStore sharedStore] favoriteStatusWithId:status._id withCompletion:^(BOOL success, NSError *error) {
            if (success) {
                status.favourited = YES;
                self.favoriteButton.tintColor = DW_FAVORITED_ICON_TINT_COLOR;
                [[NSNotificationCenter defaultCenter] postNotificationName:DW_STATUS_FAVORITED_NOTIFICATION object:status._id];
            }
        }];
    }
}


- (IBAction)ellipsesButtonPressed:(id)sender
{
    UIAlertController *optionController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [optionController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Open in Safari", @"Open in Safari") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        MSStatus *status = self.status.reblog ? self.status.reblog : self.status;
        [self.delegate timelineCell:self didSelectURL:[NSURL URLWithString:status.url]];
    }]];
    
    [optionController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Share", @"Share") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        MSStatus *status = self.status.reblog ? self.status.reblog : self.status;

        NSArray *activityItems = [NSArray arrayWithObject:[NSURL URLWithString:status.url]];
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        
        [[[UIApplication sharedApplication] topController] presentViewController:activityViewController animated:YES completion:nil];
        
    }]];
    
    [optionController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Copy text", @"Copy text") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        MSStatus *status = self.status.reblog ? self.status.reblog : self.status;

        [UIPasteboard generalPasteboard].string = status.content;
        
    }]];
    
    [optionController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Translate text", @"Translate text") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        MSStatus *status = self.status.reblog ? self.status.reblog : self.status;
        
        NSString *encodedStatus = [status.content stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSString *url = [NSString stringWithFormat:@"https://translate.google.com/#auto/auto/%@", encodedStatus];
        
        [self.delegate timelineCell:self didSelectURL:[NSURL URLWithString:url]];
    }]];
    
    if ([self.status.account._id isEqualToString:[[[MSUserStore sharedStore] currentUser] _id]]) {
        
        [optionController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", @"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            
            [[MSStatusStore sharedStore] deleteStatusWithId:self.status._id withCompletion:^(BOOL success, NSError *error) {
                
                if (success) {
                    [self.delegate timelineCell:self didDeleteStatus:self.status];
                }
                else
                {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Failed to delete status with error:", @"Failed to delete status with error:"), error.localizedFailureReason] preferredStyle:UIAlertControllerStyleAlert];
                    
                    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
                    [[[UIApplication sharedApplication] topController] presentViewController:alertController animated:YES completion:nil];

                }
                
            }];
            
        }]];
    }
    else
    {
        
        [optionController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Mention", @"Mention") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [self.delegate timelineCell:self didMentionUser:self.status.account.acct];
            
        }]];
        
        [optionController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Mute", @"Mute") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [[MSUserStore sharedStore] muteUserWithId:self.status.account._id withCompletion:^(BOOL success, NSError *error) {
                
                if (success) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:DW_NEEDS_STATUS_CLEANUP_NOTIFICATION object:self.status.account];
                        [self.delegate timelineCell:self didBlockUser:self.status.account];
                    });
                }
                else
                {

                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Failed to mute user with error:", @"Failed to mute user with error:"), error.localizedFailureReason] preferredStyle:UIAlertControllerStyleAlert];
                    
                    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
                    [[[UIApplication sharedApplication] topController] presentViewController:alertController animated:YES completion:nil];
                }
                
            }];
            
        }]];
        
        [optionController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Block", @"Block") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            
            [[MSUserStore sharedStore] blockUserWithId:self.status.account._id withCompletion:^(BOOL success, NSError *error) {
                
                if (success) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:DW_NEEDS_STATUS_CLEANUP_NOTIFICATION object:self.status.account];
                        [self.delegate timelineCell:self didBlockUser:self.status.account];
                    });

                }
                else
                {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Failed to mute user with error:", @"Failed to mute user with error:"), error.localizedFailureReason] preferredStyle:UIAlertControllerStyleAlert];
                    
                    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
                    [[[UIApplication sharedApplication] topController] presentViewController:alertController animated:YES completion:nil];
                }
            }];
        }]];
        
        [optionController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Report", @"Report") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate timelineCell:self didReportStatus:self.status];
                [[NSNotificationCenter defaultCenter] postNotificationName:DW_NEEDS_STATUS_CLEANUP_NOTIFICATION object:self.status];
            });
            
        }]];
    }
    
    
    [optionController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    
    [[[UIApplication sharedApplication] topController] presentViewController:optionController animated:YES completion:nil];
}


- (IBAction)warningTagButtonPressed:(id)sender
{
    if (sender == self.contentWarningGestureRecognizer && self.warningTagButton.selected) {
        return;
    }
    
    self.warningTagButton.selected = !self.warningTagButton.selected;
    
    CGFloat warningTagAlpha = self.warningTagButton.selected ? 0.0f : 1.0f;
    
    self.warningTagView.hidden = NO;
    [UIView animateWithDuration:0.2 animations:^{
        self.warningTagView.alpha = warningTagAlpha;
    } completion:^(BOOL finished) {
        self.warningTagView.hidden = self.warningTagView.alpha == 0.0f;
    }];
}


#pragma mark - Initialization

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.contentLabel.delegate = self;
    self.contentLabel.linkAttributes = @{(id)kCTForegroundColorAttributeName: DW_LINK_TINT_COLOR};
    self.contentLabel.activeLinkAttributes = @{(id)kCTForegroundColorAttributeName: DW_BASE_ICON_TINT_COLOR};
    self.contentLabel.inactiveLinkAttributes = @{(id)kCTForegroundColorAttributeName: DW_BASE_ICON_TINT_COLOR};
    
    if (self.retootCountImage) {
        UIImage *retootImage = self.retootCountImage.image;
        self.retootCountImage.image = nil;
        self.retootCountImage.image = retootImage;
    }
    
    if (self.favoriteCountImage) {
        UIImage *favoriteImage = self.favoriteCountImage.image;
        self.favoriteCountImage.image = nil;
        self.favoriteCountImage.image = favoriteImage;
    }
    
    self.contentWarningGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(warningTagButtonPressed:)];
    [self.warningTagView addGestureRecognizer:self.contentWarningGestureRecognizer];
    
    
    [self.warningTagButton setTitle:@"" forState:UIControlStateNormal];
    [self.warningTagButton setTitle:@"" forState:UIControlStateSelected];
    [self.warningTagButton setImage:[[UIImage imageNamed:@"HideIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateNormal];
    [self.warningTagButton setImage:[[UIImage imageNamed:@"ShowIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] forState:UIControlStateSelected];
    
    [self configureForReuse];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self configureForReuse];
}


- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    // workaround to kick intrinsic sizing to work properly
    //[self layoutIfNeeded];
}


#pragma mark - Getter/Setter Overrides

- (void)setStatus:(MSStatus *)status
{
    _status = status;
    [self configureViews];
}


- (void)setNotification:(MSNotification *)notification
{
    _notification = notification;
    
    self.status = notification.status;
}


#pragma mark - TTTAttributedLabel Delegate Methods

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    if ([url.scheme isEqualToString:@"user"]) {
        
        MSStatus *status = self.status.reblog ? self.status.reblog : self.status;
        
        MSMention *selectedAccount = [[status.mentions filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"acct CONTAINS[cd] %@", [url.host substringFromIndex:1]]] firstObject];
        
        [self.delegate timelineCell:self didSelectUser:selectedAccount._id];
    }
    else if ([url.scheme isEqualToString:@"hashtag"])
    {
        DWTimelineViewController *hashtagController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"HashtagController"];
        hashtagController.hashtag = [[[url.resourceSpecifier substringFromIndex:1] stringByRemovingPercentEncoding] substringFromIndex:2];
        DWNavigationViewController *navController = [[DWNavigationViewController alloc] initWithRootViewController:hashtagController];
        
        [[[UIApplication sharedApplication] topController] presentViewController:navController animated:YES completion:nil];
        
    }
    else
    {
        [self.delegate timelineCell:self didSelectURL:url];
    }
}


#pragma mark - Private Methods

- (void)configureForReuse
{
    _notification = nil;
    _status = nil;
    self.avatarImageView.image = nil;
    self.displayLabel.text = @"";
    self.usernameLabel.text = @"";
    self.dateLabel.text = @"";
    self.contentLabel.text = @"";
    self.retootButton.enabled = YES;
    self.retootButton.tintColor = DW_BASE_ICON_TINT_COLOR;
    self.favoriteButton.tintColor = DW_BASE_ICON_TINT_COLOR;
    self.warningTagButton.hidden = YES;
    self.warningTagButton.selected = NO;
    self.warningTagLabel.text = @"";
    self.warningTagView.hidden = YES;
    self.warningTagView.alpha = 1.0f;
    self.retootCountLabel.text = @"";
    self.favoriteCountLabel.text = @"";
    self.warningTagTopMediaConstraint.active = NO;
    self.warningTagTopLabelConstraint.active = YES;
    
    self.contentLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.displayLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.usernameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.dateLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.warningTagLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.retootCountLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.favoriteCountLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
}


- (void)configureViews
{
    MSStatus *status = self.status.reblog ? self.status.reblog : self.status;
    MSAccount *author = status.account;
    
    self.isThreadStatus = self.retootCountLabel != nil;
    
    if (author.avatar) {
        [self.avatarImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[[DWSettingStore sharedStore] disableGifPlayback] ? status.account.avatar_static : status.account.avatar]] placeholderImage:nil success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
            self.avatarImageView.image = image;
            if ([[DWSettingStore sharedStore] disableGifPlayback]) {
                [self.avatarImageView stopAnimating];
            }
        } failure:nil];
    }
    
    if (author.display_name) {
        self.displayLabel.text = author.display_name.length ? author.display_name : author.username;
    }
    
    if (author.acct) {
        self.usernameLabel.text = [NSString stringWithFormat:@"@%@", author.acct];
    }
    
    if (status.created_at) {
        self.dateLabel.text = self.isThreadStatus ? [NSString stringWithFormat:@"%@ %@ •%@", [status.created_at formattedDateWithStyle:NSDateFormatterMediumStyle], [status.created_at formattedDateWithFormat:@"HH:mm"], status.application.name ? [NSString stringWithFormat:@" %@ •", status.application.name] : @""] : [status.created_at shortTimeAgoSinceNow];
        self.dateLabel.accessibilityLabel = self.isThreadStatus ? [NSString stringWithFormat:@"%@ %@ •%@", [status.created_at formattedDateWithStyle:NSDateFormatterMediumStyle], [status.created_at formattedDateWithFormat:@"HH:mm"], status.application.name ? [NSString stringWithFormat:@" %@ •", status.application.name] : @""] : [status.created_at timeAgoSinceNow];
    }
    
    if (status.content) {
        self.contentLabel.text = status.content;
        [self highlightUsersInContentLabel:self.contentLabel forStatus:status];
        [self.contentLabel setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]];
        self.dateLabel.accessibilityLabel = [self.dateLabel.accessibilityLabel stringByAppendingFormat:@". %@", status.content];
    }
    
    self.retootButton.enabled = ![status.visibility isEqualToString:MS_VISIBILITY_TYPE_PRIVATE] && ![status.visibility isEqualToString:MS_VISIBILITY_TYPE_DIRECT];
    
    if ([status.visibility isEqualToString:MS_VISIBILITY_TYPE_DIRECT]) {
        [self.retootButton setImage:[UIImage imageNamed:@"DirectMessageIcon"] forState:UIControlStateDisabled];
    }
    else
    {
        [self.retootButton setImage:[UIImage imageNamed:@"PrivateIcon"] forState:UIControlStateDisabled];
    }
    
    self.favoriteButton.tintColor = status.favourited ? DW_FAVORITED_ICON_TINT_COLOR : DW_BASE_ICON_TINT_COLOR;
    self.retootButton.tintColor = status.reblogged ? DW_BLUE_COLOR : DW_BASE_ICON_TINT_COLOR;
    self.retootCountLabel.text = [NSString stringWithFormat:@"%@ •", status.reblogs_count];
    self.favoriteCountLabel.text = [NSString stringWithFormat:@"%@", status.favourites_count];
    
    if (status.spoiler_text.length || (status.sensitive && status.media_attachments.count)) {
        
        self.warningTagView.hidden = NO;
        self.warningTagButton.hidden = NO;
        self.warningTagLabel.text = [NSString stringWithFormat:@"%@\n%@", status.spoiler_text.length ? status.spoiler_text : NSLocalizedString(@"Sensitive content", @"Sensitive content"), NSLocalizedString(@"Hold to show", @"Hold to show")];
    }
    
    if (!status.spoiler_text.length && status.sensitive && status.media_attachments.count) {
        
        self.warningTagTopLabelConstraint.active = NO;
        self.warningTagTopMediaConstraint.active = YES;
        
        [self.contentView layoutIfNeeded];
    }
}


- (void)highlightUsersInContentLabel:(TTTAttributedLabel *)attributedLabel forStatus:(MSStatus *)status
{
    NSArray *URLs = [TwitterText URLsInText:status.content];
    NSArray *mentions = [TwitterText mentionedScreenNamesInText:status.content];
    NSArray *hashtags = [TwitterText hashtagsInText:status.content checkingURLOverlap:YES];
    
    for (TwitterTextEntity *entity in URLs) {
        
        NSURL *url = [NSURL URLWithString:[status.content substringWithRange:entity.range]];
        [attributedLabel addLinkToURL:url withRange:entity.range];
    }
    
    for (TwitterTextEntity *entity in mentions) {
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"user://%@", [status.content substringWithRange:entity.range]]];
        [attributedLabel addLinkToURL:url withRange:entity.range];
    }
    
    for (TwitterTextEntity *entity in hashtags) {
        
        NSURL *url = [NSURL URLWithString:[[NSString stringWithFormat:@"hashtag://%@", [status.content substringWithRange:entity.range]] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]]];
        [attributedLabel addLinkToURL:url withRange:entity.range];
    }
}

@end
