//
//  DWTimelineFollowTableViewCell.m
//  DireFloof
//
//  Created by John Gabelmann on 2/16/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <AFNetworking/UIImageView+AFNetworking.h>
#import "DWTimelineFollowTableViewCell.h"
#import "DWConstants.h"
#import "UIApplication+TopController.h"
#import "DWSettingStore.h"
#import "UIAlertController+SupportedInterfaceOrientations.h"

@interface DWTimelineFollowTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *followerLabel;
@property (nonatomic, weak) IBOutlet UILabel *followerDisplayNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *followerUsernameLabel;
@property (nonatomic, weak) IBOutlet UIImageView *followerAvatarImageView;
@property (nonatomic, weak) IBOutlet UIButton *followButton;
@property (nonatomic, weak) IBOutlet UIImageView *followImageView;
@property (nonatomic, weak) IBOutlet UILabel *followedYouLabel;

@property (nonatomic, assign) BOOL loadedFollowStatus;
@property (nonatomic, assign) BOOL loadingFollowStatus;

@property (nonatomic, assign) BOOL isBlocked;
@property (nonatomic, assign) BOOL isFollowing;

@end

@implementation DWTimelineFollowTableViewCell

#pragma mark - Actions

- (IBAction)followButtonPressed:(id)sender
{
    if (!self.loadedFollowStatus) {
        return;
    }
    
    self.loadedFollowStatus = NO;
    
    if (self.showMuteStatus) {
        
        if (!self.followButton.selected) {
            [[MSUserStore sharedStore] muteUserWithId:self.account._id withCompletion:^(BOOL success, NSError *error) {
                self.loadedFollowStatus = YES;
                
                if (success) {
                    self.followButton.selected = YES;
                    self.followButton.tintColor = DW_BLUE_COLOR;
                    self.followButton.accessibilityLabel = NSLocalizedString(@"Unmute", @"Unmute");
                }
                else
                {
                    self.followButton.selected = NO;
                    self.followButton.tintColor = DW_LINK_TINT_COLOR;
                    
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %li", NSLocalizedString(@"Failed to mute user with error:", @"Failed to mute user with error:"), (long)error.code] preferredStyle:UIAlertControllerStyleAlert];
                    
                    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
                    [[[UIApplication sharedApplication] topController] presentViewController:alertController animated:YES completion:nil];
                }
                
            }];
        }
        else
        {
            [[MSUserStore sharedStore] unmuteUserWithId:self.account._id withCompletion:^(BOOL success, NSError *error) {
                self.loadedFollowStatus = YES;
                
                if (success) {
                    self.followButton.selected = NO;
                    self.followButton.tintColor = DW_LINK_TINT_COLOR;
                    self.followButton.accessibilityLabel = NSLocalizedString(@"Mute", @"Mute");
                }
                else
                {
                    self.followButton.selected = YES;
                    self.followButton.tintColor = DW_BLUE_COLOR;
                    
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %li", NSLocalizedString(@"Failed to unmute user with error:", @"Failed to unmute user with error:"), (long)error.code] preferredStyle:UIAlertControllerStyleAlert];
                    
                    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
                    [[[UIApplication sharedApplication] topController] presentViewController:alertController animated:YES completion:nil];
                }
            }];
        }
    }
    else if (!self.followButton.selected) {
        self.followButton.selected = YES;
        self.followButton.tintColor = DW_BLUE_COLOR;
        
        if ([self.account.username isEqualToString:self.account.acct]) {
            [[MSUserStore sharedStore] followUserWithId:self.account._id withCompletion:^(BOOL success, NSError *error) {
                
                
                if (success) {
                    self.loadedFollowStatus = YES;

                    self.followButton.selected = YES;
                    self.followButton.tintColor = DW_BLUE_COLOR;
                    self.followButton.accessibilityLabel = NSLocalizedString(@"Unfollow", @"Unfollow");
                }
                else
                {
                    [[MSUserStore sharedStore] getRelationshipsToUsers:@[self.account._id] withCompletion:^(BOOL success, NSDictionary *relationships, NSError *error) {
                        
                        self.loadedFollowStatus = YES;

                        if (success) {
                            
                            BOOL following = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_FOLLOWING] integerValue] > 0;
                            BOOL requested = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_REQUESTED] integerValue] > 0;
                            
                            self.followButton.selected = following;
                            self.followButton.tintColor = following ? DW_BLUE_COLOR : DW_BASE_ICON_TINT_COLOR;
                            
                            if (requested) {
                                [self.followButton setImage:[UIImage imageNamed:@"HourglassIcon"] forState:UIControlStateNormal];
                            }
                            else
                            {
                                self.followButton.accessibilityLabel = following ? NSLocalizedString(@"Unfollow", @"Unfollow") : NSLocalizedString(@"Follow", @"Follow");
                            }
                        }
                        else
                        {
                        }
                    }];
                }
            }];
        }
        else
        {
            [[MSUserStore sharedStore] getRemoteUserWithLongformUsername:self.account.acct withCompletion:^(BOOL success, MSAccount *localUser, NSError *error) {
                if (success) {
                    [[MSUserStore sharedStore] followUserWithId:self.account._id withCompletion:^(BOOL success, NSError *error) {
                        
                        self.loadedFollowStatus = YES;
                        
                        if (success) {
                            self.followButton.selected = YES;
                            self.followButton.tintColor = DW_BLUE_COLOR;
                            self.followButton.accessibilityLabel = NSLocalizedString(@"Unfollow", @"Unfollow");
                        }
                        else
                        {
                            [[MSUserStore sharedStore] getRelationshipsToUsers:@[self.account._id] withCompletion:^(BOOL success, NSDictionary *relationships, NSError *error) {
                                self.loadedFollowStatus = YES;
                                
                                if (success) {
                                    
                                    BOOL following = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_FOLLOWING] integerValue] > 0;
                                    BOOL requested = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_REQUESTED] integerValue] > 0;
                                    
                                    self.followButton.selected = following;
                                    self.followButton.tintColor = following ? DW_BLUE_COLOR : DW_BASE_ICON_TINT_COLOR;
                                    
                                    if (requested) {
                                        [self.followButton setImage:[UIImage imageNamed:@"HourglassIcon"] forState:UIControlStateNormal];
                                    }
                                    else
                                    {
                                        self.followButton.accessibilityLabel = following ? NSLocalizedString(@"Unfollow", @"Unfollow") : NSLocalizedString(@"Follow", @"Follow");
                                    }
                                }
                                else
                                {
                                }
                            }];
                        }
                    }];
                }
                else
                {
                    [[MSUserStore sharedStore] getRelationshipsToUsers:@[self.account._id] withCompletion:^(BOOL success, NSDictionary *relationships, NSError *error) {
                        self.loadedFollowStatus = YES;

                        if (success) {
                            
                            BOOL following = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_FOLLOWING] integerValue] > 0;
                            BOOL requested = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_REQUESTED] integerValue] > 0;
                            
                            self.followButton.selected = following;
                            self.followButton.tintColor = following ? DW_BLUE_COLOR : DW_BASE_ICON_TINT_COLOR;
                            
                            if (requested) {
                                [self.followButton setImage:[UIImage imageNamed:@"HourglassIcon"] forState:UIControlStateNormal];
                            }
                            else
                            {
                                self.followButton.accessibilityLabel = following ? NSLocalizedString(@"Unfollow", @"Unfollow") : NSLocalizedString(@"Follow", @"Follow");
                            }
                        }
                        else
                        {
                        }
                    }];
                }
            }];
        }
    }
    else if (self.isBlocked)
    {
        [[MSUserStore sharedStore] unblockUserWithId:self.account._id withCompletion:^(BOOL success, NSError *error) {
            
            if (success) {
                [[MSUserStore sharedStore] getRelationshipsToUsers:@[self.account._id] withCompletion:^(BOOL success, NSDictionary *relationships, NSError *error) {
                    if (success) {
                        BOOL following = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_FOLLOWING] integerValue] > 0;
                        BOOL blocking = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_BLOCKING] integerValue] > 0;
                        self.isBlocked = blocking;
                        self.isFollowing = following;
                        
                        self.followButton.selected = following || blocking;
                        self.followButton.tintColor = following || blocking ? DW_BLUE_COLOR : DW_LINK_TINT_COLOR;
                        [self.followButton setImage:(blocking ? [UIImage imageNamed:@"UnblockIcon"] : [UIImage imageNamed:@"UnfollowUserIcon"]) forState:UIControlStateSelected];
                        [self.followButton setImage:[UIImage imageNamed:@"FollowUserIcon"] forState:UIControlStateNormal];
                        self.followButton.accessibilityLabel = blocking ? NSLocalizedString(@"Unblock", @"Unblock") : following ? NSLocalizedString(@"Unfollow", @"Unfollow") : NSLocalizedString(@"Follow", @"Follow");

                        self.loadedFollowStatus = YES;
                    }
                }];
            }
            else
            {
                self.loadedFollowStatus = YES;
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %li", NSLocalizedString(@"Failed to unblock user with error:", @"Failed to unblock user with error:"), (long)error.code] preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
                [[[UIApplication sharedApplication] topController] presentViewController:alertController animated:YES completion:nil];
            }
        }];
    }
    else
    {
        self.followButton.selected = NO;
        self.followButton.tintColor = DW_LINK_TINT_COLOR;
        
        [[MSUserStore sharedStore] unfollowUserWithId:self.account._id withCompletion:^(BOOL success, NSError *error) {
            
            self.loadedFollowStatus = YES;
            
            if (success) {
                self.followButton.selected = NO;
                self.followButton.tintColor = DW_LINK_TINT_COLOR;
                self.followButton.accessibilityLabel = NSLocalizedString(@"Follow", @"Follow");
            }
            else
            {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %li", NSLocalizedString(@"Failed to unfollow user with error:", @"Failed to unfollow user with error:"), (long)error.code] preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
                [[[UIApplication sharedApplication] topController] presentViewController:alertController animated:YES completion:nil];
            }
        }];
    }
}


- (IBAction)rejectButtonPressed:(id)sender
{
    [[MSUserStore sharedStore] rejectFollowRequestWithId:self.account._id withCompletion:^(BOOL success, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DW_DID_ANSWER_FOLLOW_REQUEST_NOTIFICATION object:self];
    }];
}


- (IBAction)authorizeButtonPressed:(id)sender
{
    [[MSUserStore sharedStore] authorizeFollowRequestWithId:self.account._id withCompletion:^(BOOL success, NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:DW_DID_ANSWER_FOLLOW_REQUEST_NOTIFICATION object:self];
    }];
}


#pragma mark - Initialization

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    // Workaround for tinting bullshit
    UIImage *image = self.followImageView.image;
    self.followImageView.image = nil;
    self.followImageView.image = image;
    
    [self configureForReuse];
}


- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self configureForReuse];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

#pragma mark - Getter/Setter Overrides

- (void)setNotification:(MSNotification *)notification
{
    _notification = notification;
    _account = notification.account;
    
    [self configureViews];
}


- (void)setAccount:(MSAccount *)account
{
    _account = account;
    
    [self configureViews];
}


#pragma mark - Private Methods

- (void)configureViews
{
    MSAccount *follower = self.account;
    
    if (follower.avatar) {
        
        [self.followerAvatarImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[[DWSettingStore sharedStore] disableGifPlayback] ? follower.avatar_static : follower.avatar]] placeholderImage:nil success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
            self.followerAvatarImageView.image = image;
            if ([[DWSettingStore sharedStore] disableGifPlayback]) {
                [self.followerAvatarImageView stopAnimating];
            }
        } failure:nil];
    }
    
    if (follower.display_name) {
        self.followerLabel.text = follower.display_name.length ? follower.display_name : follower.username;
        self.followerDisplayNameLabel.text = follower.display_name.length ? follower.display_name : follower.username;
    }
    
    if (follower.acct) {
        self.followerUsernameLabel.text = [NSString stringWithFormat:@"@%@", follower.acct];
        
        if (!self.followerLabel.text.length) {
            self.followerLabel.text = follower.acct;
        }
    }
    
    if (self.followButton && self.notification) {
        if (!self.loadedFollowStatus && !self.loadingFollowStatus) {
            self.loadingFollowStatus = YES;
            [[MSUserStore sharedStore] getRelationshipsToUsers:@[follower._id] withCompletion:^(BOOL success, NSDictionary *relationships, NSError *error) {
                if (success) {
                    BOOL following = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_FOLLOWING] integerValue] > 0;
                    BOOL blocking = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_BLOCKING] integerValue] > 0;
                    BOOL requested = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_REQUESTED] integerValue] > 0;
                    
                    self.isBlocked = blocking;
                    self.isFollowing = following;
                    
                    if (requested && !blocking) {
                        [self.followButton setImage:[UIImage imageNamed:@"HourglassIcon"] forState:UIControlStateNormal];
                        self.followButton.userInteractionEnabled = NO;
                    }
                    else
                    {
                        self.followButton.selected = following || blocking;
                        self.followButton.tintColor = following || blocking ? DW_BLUE_COLOR : DW_LINK_TINT_COLOR;
                        [self.followButton setImage:(blocking ? [UIImage imageNamed:@"UnblockIcon"] : [UIImage imageNamed:@"UnfollowUserIcon"]) forState:UIControlStateSelected];
                        self.followButton.accessibilityLabel = blocking ? NSLocalizedString(@"Unblock", @"Unblock") : following ? NSLocalizedString(@"Unfollow", @"Unfollow") : NSLocalizedString(@"Follow", @"Follow");
                    }
                    
                    self.loadedFollowStatus = YES;
                }
                
                self.loadingFollowStatus = NO;
            }];
        }
    }
    else if (self.showMuteStatus)
    {
        self.followButton.tintColor = DW_BLUE_COLOR;
        self.followButton.selected = YES;
        [self.followButton setImage:[UIImage imageNamed:@"MuteIcon"] forState:UIControlStateSelected];
        [self.followButton setImage:[UIImage imageNamed:@"UnmuteIcon"] forState:UIControlStateNormal];
        self.followButton.accessibilityLabel = NSLocalizedString(@"Unmute", @"Unmute");
        self.loadedFollowStatus = YES;
    }
    else if (!self.isRequest)
    {
        self.followButton.tintColor = DW_BLUE_COLOR;
        self.followButton.selected = YES;
        [self.followButton setImage:[UIImage imageNamed:@"UnblockIcon"] forState:UIControlStateSelected];
        self.followButton.accessibilityLabel = NSLocalizedString(@"Unblock", @"Unblock");
        self.loadedFollowStatus = YES;
        self.isBlocked = YES;
    }
    
}


- (void)configureForReuse
{
    _notification = nil;
    _account = nil;
    self.loadedFollowStatus = NO;
    self.loadingFollowStatus = NO;
    self.followerLabel.text = @"";
    self.followerAvatarImageView.image = nil;
    self.followerUsernameLabel.text = @"";
    self.followerDisplayNameLabel.text = @"";
    self.followButton.selected = NO;
    self.followButton.tintColor = DW_LINK_TINT_COLOR;
    self.isFollowing = NO;
    self.isBlocked = NO;
    
    self.followedYouLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.followerLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.followerUsernameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.followerDisplayNameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

@end
