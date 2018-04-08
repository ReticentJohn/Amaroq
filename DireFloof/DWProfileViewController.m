//
//  DWProfileViewController.m
//  DireFloof
//
//  Created by John Gabelmann on 2/27/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <ActiveLabel/ActiveLabel-Swift.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "DWProfileViewController.h"
#import "DWTimelineTableViewCell.h"
#import "DWTimelineMediaTableViewCell.h"
#import "DWTimelineFollowTableViewCell.h"
#import "DWConstants.h"
#import "DWComposeViewController.h"
#import "UIView+Supercell.h"
#import "UIApplication+TopController.h"
#import "DWTimelineViewController.h"
#import "UIViewController+NearestNavigationController.h"
#import "DWSettingStore.h"
#import "UIViewController+WebNavigation.h"
#import "DWNavigationViewController.h"
#import "UIAlertController+SupportedInterfaceOrientations.h"

typedef NS_ENUM(NSUInteger, DWProfileSectionType) {
    DWProfileSectionTypePosts                = 0,
    DWProfileSectionTypeFollowing            = 1,
    DWProfileSectionTypeFollowers            = 2,
};

@interface DWProfileViewController () <UITableViewDelegate, UITableViewDataSource, DWTimelineTableViewCellDelegate>

@property (nonatomic, weak) IBOutlet UIButton *followingYouButton;
@property (nonatomic, weak) IBOutlet UIButton *followingButton;
@property (nonatomic, weak) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, weak) IBOutlet UIImageView *headerImageView;
@property (nonatomic, weak) IBOutlet UILabel *displayNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *usernameLabel;
@property (nonatomic, weak) IBOutlet ActiveLabel *bioLabel;
@property (nonatomic, weak) IBOutlet UILabel *postCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *followingCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *followerCountLabel;
@property (nonatomic, weak) IBOutlet UILabel *postLabel;
@property (nonatomic, weak) IBOutlet UILabel *followsLabel;
@property (nonatomic, weak) IBOutlet UILabel *followersLabel;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *pageLoadingView;

@property (nonatomic, weak) IBOutlet UINavigationBar *floatingNav;
@property (nonatomic, weak) IBOutlet UIButton *scrollToTopButton;

@property (nonatomic, assign) DWProfileSectionType currentSection;
@property (nonatomic, strong) MSTimeline *timeline;
@property (nonatomic, strong) NSArray *followers;
@property (nonatomic, strong) NSArray *following;
@property (nonatomic, strong) NSString *followersNextUrl;
@property (nonatomic, strong) NSString *followingNextUrl;

@property (nonatomic, strong) NSMutableDictionary *cachedEstimatedHeights;

@property (nonatomic, assign) BOOL loadingNextTimelinePage;
@property (nonatomic, assign) BOOL loadingNextFollowersPage;
@property (nonatomic, assign) BOOL loadingNextFollowingPage;
@property (nonatomic, assign) BOOL loadedFollowedStatus;
@property (nonatomic, assign) BOOL blocking;
@property (nonatomic, assign) BOOL muting;
@end

@implementation DWProfileViewController

#pragma mark - Actions

- (IBAction)closeButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}


- (IBAction)followButtonPressed:(id)sender
{
    if (!self.loadedFollowedStatus) {
        return;
    }
    
    self.loadedFollowedStatus = NO;
    if (!self.followingButton.selected) {
        self.followingButton.selected = YES;
        self.followingButton.tintColor = DW_BLUE_COLOR;
        
        if ([self.account.username isEqualToString:self.account.acct]) {
            [[MSUserStore sharedStore] followUserWithId:self.account._id withCompletion:^(BOOL success, NSError *error) {
                if (success) {
                    self.loadedFollowedStatus = YES;

                    self.followingButton.selected = YES;
                    self.followingButton.tintColor = DW_BLUE_COLOR;
                }
                else
                {
                    [[MSUserStore sharedStore] getRelationshipsToUsers:@[self.account._id] withCompletion:^(BOOL success, NSDictionary *relationships, NSError *error) {
                        self.loadedFollowedStatus = YES;

                        if (success) {
                            
                            BOOL following = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_FOLLOWING] integerValue] > 0;
                            BOOL followingYou = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_FOLLOWED_BY] integerValue] > 0;
                            BOOL requested = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_REQUESTED] integerValue] > 0;
                            
                            self.followingButton.selected = following;
                            self.followingButton.tintColor = following ? DW_BLUE_COLOR : DW_BASE_ICON_TINT_COLOR;
                            self.followingYouButton.hidden = !followingYou;
                            
                            if (requested) {
                                [self.followingButton setImage:[UIImage imageNamed:@"HourglassIcon"] forState:UIControlStateNormal];
                                self.followingButton.userInteractionEnabled = NO;
                            }
                            
                            self.blocking = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_BLOCKING] integerValue] > 0;
                            self.muting = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_MUTING] integerValue] > 0;
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
                    [[MSUserStore sharedStore] followUserWithId:localUser._id withCompletion:^(BOOL success, NSError *error) {
                        
                        self.loadedFollowedStatus = YES;
                        
                        if (success) {
                            self.followingButton.selected = YES;
                            self.followingButton.tintColor = DW_BLUE_COLOR;
                        }
                        else
                        {
                            [[MSUserStore sharedStore] getRelationshipsToUsers:@[self.account._id] withCompletion:^(BOOL success, NSDictionary *relationships, NSError *error) {
                                self.loadedFollowedStatus = YES;
                                
                                if (success) {
                                    
                                    BOOL following = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_FOLLOWING] integerValue] > 0;
                                    BOOL followingYou = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_FOLLOWED_BY] integerValue] > 0;
                                    BOOL requested = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_REQUESTED] integerValue] > 0;
                                    
                                    self.followingButton.selected = following;
                                    self.followingButton.tintColor = following ? DW_BLUE_COLOR : DW_BASE_ICON_TINT_COLOR;
                                    self.followingYouButton.hidden = !followingYou;
                                    
                                    if (requested) {
                                        [self.followingButton setImage:[UIImage imageNamed:@"HourglassIcon"] forState:UIControlStateNormal];
                                    }
                                    
                                    self.blocking = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_BLOCKING] integerValue] > 0;
                                    self.muting = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_MUTING] integerValue] > 0;
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
                        self.loadedFollowedStatus = YES;

                        if (success) {
                            
                            BOOL following = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_FOLLOWING] integerValue] > 0;
                            BOOL followingYou = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_FOLLOWED_BY] integerValue] > 0;
                            BOOL requested = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_REQUESTED] integerValue] > 0;
                            
                            self.followingButton.selected = following;
                            self.followingButton.tintColor = following ? DW_BLUE_COLOR : DW_BASE_ICON_TINT_COLOR;
                            self.followingYouButton.hidden = !followingYou;
                            
                            if (requested) {
                                [self.followingButton setImage:[UIImage imageNamed:@"HourglassIcon"] forState:UIControlStateNormal];
                            }
                            
                            self.blocking = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_BLOCKING] integerValue] > 0;
                            self.muting = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_MUTING] integerValue] > 0;
                        }
                        else
                        {
                        }
                    }];
                }
            }];
        }
    }
    else
    {
        self.followingButton.selected = NO;
        self.followingButton.tintColor = DW_BASE_ICON_TINT_COLOR;
        [[MSUserStore sharedStore] unfollowUserWithId:self.account._id withCompletion:^(BOOL success, NSError *error) {
            
            self.loadedFollowedStatus = YES;
            
            if (success) {
                self.followingButton.selected = NO;
                self.followingButton.tintColor = DW_BASE_ICON_TINT_COLOR;
            }
            else
            {
                self.followingButton.selected = YES;
                self.followingButton.tintColor = DW_BLUE_COLOR;
                
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %li", NSLocalizedString(@"Failed to unfollow user with error:", @"Failed to unfollow user with error:"), error.code] preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        }];
    }
}


- (IBAction)menuButtonPressed:(id)sender
{
    UIAlertController *optionController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [optionController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Open in Safari", @"Open in Safari") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self openWebURL:[NSURL URLWithString:self.account.url]];
    }]];
    
    [optionController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Share", @"Share") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        NSArray *activityItems = [NSArray arrayWithObject:[NSURL URLWithString:self.account.url]];
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
        
        [[[UIApplication sharedApplication] topController] presentViewController:activityViewController animated:YES completion:nil];
        
    }]];
    
    if ([self.account._id isEqualToString:[[[MSUserStore sharedStore] currentUser] _id]]) {
        
        [optionController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Edit Profile", @"Edit Profile") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [[MSAuthStore sharedStore] requestEditProfile];
        }]];
    }
    else
    {
        [optionController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Mention", @"Mention") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [self performSegueWithIdentifier:@"MentionSegue" sender:self.account.acct];
            
        }]];
        
        [optionController addAction:[UIAlertAction actionWithTitle:self.muting ? NSLocalizedString(@"Unmute", @"Unmute") : NSLocalizedString(@"Mute", @"Mute") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            if (!self.muting) {
                [[MSUserStore sharedStore] muteUserWithId:self.account._id withCompletion:^(BOOL success, NSError *error) {
                    
                    if (success) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.muting = YES;
                            [[NSNotificationCenter defaultCenter] postNotificationName:DW_NEEDS_STATUS_CLEANUP_NOTIFICATION object:self.account];
                        });
                    }
                    else
                    {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %li", NSLocalizedString(@"Failed to mute user with error:", @"Failed to mute user with error:"), error.code] preferredStyle:UIAlertControllerStyleAlert];
                        
                        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
                        [self presentViewController:alertController animated:YES completion:nil];
                    }
                }];
            }
            else
            {
                [[MSUserStore sharedStore] unmuteUserWithId:self.account._id withCompletion:^(BOOL success, NSError *error) {
                    if (success) {
                        self.muting = NO;
                    }
                    else
                    {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %li", NSLocalizedString(@"Failed to unmute user with error:", @"Failed to unmute user with error:"), error.code] preferredStyle:UIAlertControllerStyleAlert];
                        
                        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
                        [self presentViewController:alertController animated:YES completion:nil];
                    }
                }];
            }
        }]];
        
        [optionController addAction:[UIAlertAction actionWithTitle:self.blocking ? NSLocalizedString(@"Unblock", @"Unblock") : NSLocalizedString(@"Block", @"Block") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            
            if (!self.blocking) {
                [[MSUserStore sharedStore] blockUserWithId:self.account._id withCompletion:^(BOOL success, NSError *error) {
                    
                    if (success) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.blocking = YES;
                            [[NSNotificationCenter defaultCenter] postNotificationName:DW_NEEDS_STATUS_CLEANUP_NOTIFICATION object:self.account];
                            [self.navigationController popViewControllerAnimated:YES];
                        });
                        
                    }
                    else
                    {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %li", NSLocalizedString(@"Failed to block user with error:", @"Failed to block user with error:"), error.code] preferredStyle:UIAlertControllerStyleAlert];
                        
                        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
                        [self presentViewController:alertController animated:YES completion:nil];
                    }
                }];
            }
            else
            {
                [[MSUserStore sharedStore] unblockUserWithId:self.account._id withCompletion:^(BOOL success, NSError *error) {
                    if (success) {
                        self.blocking = NO;
                    }
                    else
                    {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %li", NSLocalizedString(@"Failed to unblock user with error:", @"Failed to unblock user with error:"), error.code] preferredStyle:UIAlertControllerStyleAlert];
                        
                        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
                        [self presentViewController:alertController animated:YES completion:nil];
                    }
                }];
            }
        }]];
        
        NSArray *domainComponents = [self.account.acct componentsSeparatedByString:@"@"];
        
        if (domainComponents.count > 1) {
            
            NSString *domain = [domainComponents lastObject];
            
            [optionController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Block entire domain", @"Block entire domain") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                
                [[MSAppStore sharedStore] blockMastodonInstance:domain withCompletion:^(BOOL success, NSError *error) {
                    
                    if (success) {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Blocked domain", @"Blocked domain") message:NSLocalizedString(@"Users of this domain will no longer show in public or local timelines.", @"Users of this domain will no longer show in public or local timelines.") preferredStyle:UIAlertControllerStyleAlert];
                        
                        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
                        [self presentViewController:alertController animated:YES completion:nil];
                    }
                    else
                    {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %li", NSLocalizedString(@"Failed to block domain with error:", @"Failed to block domain with error:"), error.code] preferredStyle:UIAlertControllerStyleAlert];
                        
                        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
                        [self presentViewController:alertController animated:YES completion:nil];
                    }
                }];
            }]];
        }
    }
    
    [optionController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    
    [[[UIApplication sharedApplication] topController] presentViewController:optionController animated:YES completion:nil];
}


- (IBAction)profileSectionButtonPressed:(UIButton *)sender
{
    self.currentSection = sender.tag;
    [self.tableView reloadData];
}


- (IBAction)scrollToTop:(id)sender
{
    [self.tableView scrollRectToVisible:self.tableView.tableHeaderView.frame animated:YES];
}


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.cachedEstimatedHeights = [NSMutableDictionary dictionary];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustFonts) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.tintColor = [UIColor whiteColor];
    refreshControl.tag = 9001;
    [refreshControl addTarget:self action:@selector(refreshData) forControlEvents:UIControlEventValueChanged];
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
        [self.tableView addSubview:refreshControl];
    }
    else
    {
        [self.tableView setRefreshControl:refreshControl];
    }
    
    [self.bioLabel customize:^(ActiveLabel *label) {
        label.mentionColor = DW_LINK_TINT_COLOR;
        label.mentionSelectedColor =  DW_BASE_ICON_TINT_COLOR;
        label.hashtagColor = DW_LINK_TINT_COLOR;
        label.hashtagSelectedColor = DW_BASE_ICON_TINT_COLOR;
        label.URLColor = DW_LINK_TINT_COLOR;
        label.URLSelectedColor = DW_BASE_ICON_TINT_COLOR;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.numberOfLines = 0;
        
        [label handleURLTap:^(NSURL *url) {
            [self openWebURL:url];
        }];
        
        [label handleHashtagTap:^(NSString *tag) {
            DWTimelineViewController *hashtagController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"HashtagController"];
            hashtagController.hashtag = tag;
            DWNavigationViewController *navController = [[DWNavigationViewController alloc] initWithRootViewController:hashtagController];
            
            [[[UIApplication sharedApplication] topController] presentViewController:navController animated:YES completion:nil];
        }];
    }];
    
    [self configureData];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    
    [self configureViews];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([[self.tableView indexPathsForVisibleRows] containsObject:[NSIndexPath indexPathForRow:0 inSection:0]]) {
        [self refreshData];
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DW_WILL_PURGE_CACHE_NOTIFICATION object:nil];
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    UIViewController *topController = [[UIApplication sharedApplication] topController];
    
    return topController == self ? UIInterfaceOrientationMaskPortrait : [topController supportedInterfaceOrientations];
}


- (BOOL)shouldAutorotate
{
    UIViewController *topController = [[UIApplication sharedApplication] topController];
    
    return topController == self ? NO : [topController shouldAutorotate];
}


- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    
    [self.cachedEstimatedHeights removeAllObjects];
}


#pragma mark - Navigation

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"ProfileSegue"]) {
        MSAccount *selectedAccount = nil;
        if ([sender isKindOfClass:[MSAccount class]]) {
            selectedAccount = sender;
        }
        else
        {
            UITableViewCell *selectedCell = [sender supercell];
            
            NSIndexPath *selectedIndex = [self.tableView indexPathForCell:selectedCell];
            
            switch (self.currentSection) {
                case DWProfileSectionTypePosts:
                {
                    MSStatus *selectedStatus = [self.timeline.statuses objectAtIndex:selectedIndex.row];
                    selectedAccount = selectedStatus.reblog ? selectedStatus.reblog.account : selectedStatus.account;
                }
                    break;
                case DWProfileSectionTypeFollowers:
                    selectedAccount = [self.followers objectAtIndex:selectedIndex.row];
                    break;
                case DWProfileSectionTypeFollowing:
                    selectedAccount = [self.following objectAtIndex:selectedIndex.row];
                    break;
                default:
                    // ohh we are fucked if we get here
                    break;
            }
        }

        return ![selectedAccount._id isEqual:self.account._id];
    }
    
    return YES;
}

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"ComposeSegue"]) {
        
        DWComposeViewController *destinationController = segue.destinationViewController;
        destinationController.postCompleteBlock = ^(BOOL success) {
            
            if (success && [[self.tableView indexPathsForVisibleRows] containsObject:[NSIndexPath indexPathForRow:0 inSection:0]]) {
                [self refreshData];
            }
        };
    }
    else if ([segue.identifier isEqualToString:@"ReplySegue"])
    {
        UITableViewCell *selectedCell = [sender supercell];
        
        NSIndexPath *selectedIndex = [self.tableView indexPathForCell:selectedCell];
        MSStatus *selectedStatus = [self.timeline.statuses objectAtIndex:selectedIndex.row];
        if (selectedStatus.reblog) {
            selectedStatus = selectedStatus.reblog;
        }
        
        DWComposeViewController *destinationController = segue.destinationViewController;
        destinationController.replyToStatus = selectedStatus;
        destinationController.postCompleteBlock = ^(BOOL success) {
            
            if (success && [[self.tableView indexPathsForVisibleRows] containsObject:[NSIndexPath indexPathForRow:0 inSection:0]]) {
                [self refreshData];
            }
        };
    }
    else if ([segue.identifier isEqualToString:@"ReportSegue"])
    {
        MSStatus *statusToReport = sender;
        if (statusToReport.reblog) {
            statusToReport = statusToReport.reblog;
        }
        
        DWComposeViewController *destinationController = segue.destinationViewController;
        destinationController.replyToStatus = statusToReport;
        destinationController.reporting = YES;
        destinationController.postCompleteBlock = ^(BOOL success) {
            
            if (success) {
                [self.timeline purgeLocalStatus:sender];
                [self.tableView reloadData];
            }
        };
    }
    else if ([segue.identifier isEqualToString:@"ProfileSegue"])
    {
        
        MSAccount *selectedAccount = nil;
        if ([sender isKindOfClass:[MSAccount class]]) {
            selectedAccount = sender;
        }
        else
        {
            UITableViewCell *selectedCell = [sender supercell];
            
            NSIndexPath *selectedIndex = [self.tableView indexPathForCell:selectedCell];
            
            switch (self.currentSection) {
                case DWProfileSectionTypePosts:
                {
                    MSStatus *selectedStatus = [self.timeline.statuses objectAtIndex:selectedIndex.row];
                    selectedAccount = selectedStatus.reblog ? selectedStatus.reblog.account : selectedStatus.account;
                }
                    break;
                case DWProfileSectionTypeFollowers:
                    selectedAccount = [self.followers objectAtIndex:selectedIndex.row];
                    break;
                case DWProfileSectionTypeFollowing:
                    selectedAccount = [self.following objectAtIndex:selectedIndex.row];
                    break;
                default:
                    // ohh we are fucked if we get here
                    break;
            }
        }
        
        DWProfileViewController *destinationViewController = segue.destinationViewController;
        destinationViewController.account = selectedAccount;
    }
    else if ([segue.identifier isEqualToString:@"ThreadSegue"])
    {
        NSIndexPath *selectedIndex = [self.tableView indexPathForCell:sender];
        MSStatus *selectedStatus = [self.timeline.statuses objectAtIndex:selectedIndex.row];
        if (selectedStatus.reblog) {
            selectedStatus = selectedStatus.reblog;
        }
        
        DWTimelineViewController *destinationViewController = segue.destinationViewController;
        destinationViewController.threadStatus = selectedStatus.reblog ? selectedStatus.reblog : selectedStatus;
    }
    else if ([segue.identifier isEqualToString:@"MentionSegue"])
    {
        DWComposeViewController *destinationController = segue.destinationViewController;
        destinationController.mentionedUser = sender;
        destinationController.postCompleteBlock = ^(BOOL success) {
            
            if (success && [[self.tableView indexPathsForVisibleRows] containsObject:[NSIndexPath indexPathForRow:0 inSection:0]]) {
                [self refreshData];
            }
        };
    }
}


- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    if (self.presentedViewController || ![self.view viewWithTag:1337])
    {
        [super dismissViewControllerAnimated:flag completion:completion];
    }
}


#pragma mark - UITableView Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (self.currentSection) {
        case DWProfileSectionTypePosts:
            return self.timeline ? self.timeline.statuses.count : 0;
            break;
        case DWProfileSectionTypeFollowers:
            return self.followers ? self.followers.count : 0;
            break;
        case DWProfileSectionTypeFollowing:
            return self.following ? self.following.count : 0;
            break;
        default:
            break;
    }
    
    return 0;
}


- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.currentSection == DWProfileSectionTypePosts) {
        MSStatus *status = [self.timeline.statuses objectAtIndex:indexPath.row];
        
        NSNumber *cachedHeight = [self.cachedEstimatedHeights objectForKey:status._id];
        if (cachedHeight) {
            return cachedHeight.floatValue;
        }
    }
    
    return 96.0f;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.currentSection == DWProfileSectionTypePosts) {
        return [self tableView:tableView timelineCellForRowAtIndexPath:indexPath];
    }
    else
    {
        return [self tableView:tableView userCellForRowAtIndexPath:indexPath];
    }
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (self.currentSection) {
        case DWProfileSectionTypePosts:
        {
            MSStatus *status = [self.timeline.statuses objectAtIndex:indexPath.row];
            [self.cachedEstimatedHeights setObject:@(cell.bounds.size.height) forKey:status._id];
            
            if (indexPath.row >= self.timeline.statuses.count - 10 && self.timeline.nextPageUrl) {
                [self loadNextPage];
            }
        }
            break;
        case DWProfileSectionTypeFollowing:
        {
            if (indexPath.row >= self.following.count - 20 && self.followingNextUrl) {
                [self loadNextPage];
            }
        }
            break;
        case DWProfileSectionTypeFollowers:
        {
            if (indexPath.row >= self.followers.count - 20 && self.followersNextUrl) {
                [self loadNextPage];
            }
        }
            break;
        default:
            break;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (![selectedCell isKindOfClass:[DWTimelineFollowTableViewCell class]]) {
        [self performSegueWithIdentifier:@"ThreadSegue" sender:selectedCell];
    }
}


- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.y > self.tableView.tableHeaderView.bounds.size.height && self.floatingNav.hidden) {
        self.floatingNav.hidden = NO;
        self.logoImageView.hidden = NO;
        self.scrollToTopButton.hidden = NO;
        [UIView animateWithDuration:0.2 animations:^{
            self.floatingNav.alpha = 1.0f;
            self.logoImageView.alpha = 1.0f;
        }];
    }
    else if (scrollView.contentOffset.y <= self.tableView.tableHeaderView.bounds.size.height && !self.floatingNav.hidden && self.floatingNav.alpha == 1.0f)
    {
        [UIView animateWithDuration:0.2 animations:^{
            self.floatingNav.alpha = 0.0f;
            self.logoImageView.alpha = 0.0f;
        } completion:^(BOOL finished) {
            self.logoImageView.hidden = YES;
            self.floatingNav.hidden = YES;
        }];
    }
}


#pragma mark - DWTimelineTableViewCell Delegate Methods

- (void)timelineCell:(DWTimelineTableViewCell *)cell didDeleteStatus:(MSStatus *)status
{
    [self.timeline purgeLocalStatus:status];
    [self.tableView reloadData];
}


- (void)timelineCell:(DWTimelineTableViewCell *)cell didBlockUser:(MSAccount *)user
{
    [self.timeline purgeLocalStatusesByUser:user];
    [self.tableView reloadData];
}


- (void)timelineCell:(DWTimelineTableViewCell *)cell didReportStatus:(MSStatus *)status
{
    [self performSegueWithIdentifier:@"ReportSegue" sender:status];
}


- (void)timelineCell:(DWTimelineTableViewCell *)cell didMentionUser:(NSString *)user
{
    [self performSegueWithIdentifier:@"MentionSegue" sender:user];
}


- (void)timelineCell:(DWTimelineTableViewCell *)cell didSelectUser:(NSString *)user
{
    [[MSUserStore sharedStore] getUserWithId:user withCompletion:^(BOOL success, MSAccount *user, NSError *error) {
        if (success) {
            [self performSegueWithIdentifier:@"ProfileSegue" sender:user];
        }
        else
        {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %li", NSLocalizedString(@"Failed to load user with error:", @"Failed to load user with error:"), error.code] preferredStyle:UIAlertControllerStyleAlert];
            
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }];
}


- (void)timelineCell:(DWTimelineTableViewCell *)cell didSelectURL:(NSURL *)url
{
    [self openWebURL:url];
}


#pragma mark - Getter/Setter Overrides

- (void)setCurrentSection:(DWProfileSectionType)currentSection
{
    _currentSection = currentSection;
    
    [self.tableView reloadData];
}


#pragma mark - Private Methods

- (void)configureViews
{
    [self.avatarImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[[DWSettingStore sharedStore] disableGifPlayback] ? self.account.avatar_static : self.account.avatar]] placeholderImage:nil success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
        self.avatarImageView.image = image;
        if ([[DWSettingStore sharedStore] disableGifPlayback]) {
            [self.avatarImageView stopAnimating];
        }
    } failure:nil];
    
    [self.headerImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[[DWSettingStore sharedStore] disableGifPlayback] ? self.account.header_static : self.account.header]] placeholderImage:nil success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
        self.headerImageView.image = image;
        if ([[DWSettingStore sharedStore] disableGifPlayback]) {
            [self.headerImageView stopAnimating];
        }
    } failure:nil];
    
    self.displayNameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
    self.usernameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.bioLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.postCountLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.followerCountLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.followingCountLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.followsLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.followersLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.postLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    
    self.displayNameLabel.text = self.account.display_name.length ? self.account.display_name : self.account.username;
    self.usernameLabel.text = [NSString stringWithFormat:@"@%@", self.account.acct];
    self.bioLabel.text = self.account.note ? self.account.note : @"";
    self.postCountLabel.text = [self.account.statuses_count stringValue];
    self.followingCountLabel.text = [self.account.following_count stringValue];
    self.followerCountLabel.text = [self.account.followers_count stringValue];
    self.followingButton.hidden = [self.account._id isEqualToString:[[MSUserStore sharedStore] currentUser]._id];
    
    self.loadedFollowedStatus = NO;
    
    if (self.tableView.tableHeaderView) {
        CGFloat height = [self.tableView.tableHeaderView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
        CGRect headerFrame = self.tableView.tableHeaderView.frame;
        
        // If we don't have this check, viewDidLayoutSubviews() will get
        // repeatedly, causing the app to hang.
        if (height != headerFrame.size.height) {
            headerFrame.size.height = height;
            self.tableView.tableHeaderView.frame = headerFrame;
            self.tableView.tableHeaderView = self.tableView.tableHeaderView;
        }
        
        [self.tableView.tableHeaderView layoutIfNeeded];
    }
    
    [[MSUserStore sharedStore] getRelationshipsToUsers:@[self.account._id] withCompletion:^(BOOL success, NSDictionary *relationships, NSError *error) {
        if (success) {
            self.loadedFollowedStatus = YES;
            
            BOOL following = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_FOLLOWING] integerValue] > 0;
            BOOL followingYou = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_FOLLOWED_BY] integerValue] > 0;
            BOOL requested = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_REQUESTED] integerValue] > 0;
            
            self.followingButton.selected = following;
            self.followingButton.tintColor = following ? DW_BLUE_COLOR : DW_BASE_ICON_TINT_COLOR;
            self.followingYouButton.hidden = !followingYou;
            
            self.followingButton.accessibilityLabel = !following ? NSLocalizedString(@"Follow", @"Follow") : NSLocalizedString(@"Unfollow", @"Unfollow");
            
            if (requested) {
                [self.followingButton setImage:[UIImage imageNamed:@"HourglassIcon"] forState:UIControlStateNormal];
            }
            
            self.blocking = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_BLOCKING] integerValue] > 0;
            self.muting = [[relationships objectForKey:MS_FOLLOW_STATUS_KEY_MUTING] integerValue] > 0;
        }
        else
        {
        }
    }];
}


- (void)adjustFonts
{
    self.displayNameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
    self.usernameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.bioLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.postCountLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.followerCountLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.followingCountLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.followsLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.followersLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.postLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    
    if (self.tableView.tableHeaderView) {
        CGFloat height = [self.tableView.tableHeaderView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
        CGRect headerFrame = self.tableView.tableHeaderView.frame;
        
        // If we don't have this check, viewDidLayoutSubviews() will get
        // repeatedly, causing the app to hang.
        if (height != headerFrame.size.height) {
            headerFrame.size.height = height;
            self.tableView.tableHeaderView.frame = headerFrame;
            self.tableView.tableHeaderView = self.tableView.tableHeaderView;
        }
        
        [self.tableView.tableHeaderView layoutIfNeeded];
    }

}


- (void)configureData
{
    [self.pageLoadingView startAnimating];
    
    [[MSUserStore sharedStore] getUserWithId:self.account._id withCompletion:^(BOOL success, MSAccount *user, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
                UIRefreshControl *refreshControl = [self.tableView viewWithTag:9001];
                [refreshControl endRefreshing];
            }
            else
            {
                [self.tableView.refreshControl endRefreshing];
            }
            [self.pageLoadingView stopAnimating];
            
            if (success) {
                self.account = user;
                [self configureViews];
            }
            else
            {
            }
        });
    }];
    
    [[MSTimelineStore sharedStore] getStatusesForUserId:self.account._id withCompletion:^(BOOL success, MSTimeline *statuses, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                BOOL firstLoad = self.timeline == nil;
                self.timeline = statuses;
                
                if (self.currentSection == DWProfileSectionTypePosts) {
                    [self.tableView reloadData];
                    
                    if (firstLoad) {
                        [UIView setAnimationsEnabled:NO];
                        [self.tableView beginUpdates];
                        [self.tableView endUpdates];
                        [UIView setAnimationsEnabled:YES];
                    }
                }
            }
            else
            {
            }
        });
    }];
    
    [[MSUserStore sharedStore] getFollowersForUserWithId:self.account._id withCompletion:^(BOOL success, NSArray *followers, NSString *nextPageUrl, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                self.followers = followers;
                self.followersNextUrl = nextPageUrl;
                
                if (self.currentSection == DWProfileSectionTypeFollowers) {
                    [self.tableView reloadData];
                }
            }
            else
            {
            }
        });
    }];
    
    [[MSUserStore sharedStore] getFollowingForUserWithId:self.account._id withCompletion:^(BOOL success, NSArray *following, NSString *nextPageUrl, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                self.following = following;
                self.followingNextUrl = nextPageUrl;
                
                if (self.currentSection == DWProfileSectionTypeFollowing) {
                    [self.tableView reloadData];
                }
            }
            else
            {
            }
        });
    }];
}


- (void)refreshData
{
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
        UIRefreshControl *refreshControl = [self.tableView viewWithTag:9001];
        [refreshControl beginRefreshing];
    }
    else
    {
        [self.tableView.refreshControl beginRefreshing];
    }
    
    [self configureData];
}


- (void)loadNextPage
{
    switch (self.currentSection) {
        case DWProfileSectionTypePosts:
        {
            if (!self.loadingNextTimelinePage) {
                self.loadingNextTimelinePage = YES;
                
                [self.pageLoadingView startAnimating];
                
                [self.timeline loadNextPageWithCompletion:^(BOOL success, NSError *error) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.pageLoadingView stopAnimating];
                        self.loadingNextTimelinePage = NO;
                        
                        if (success && self.currentSection == DWProfileSectionTypePosts) {
                            [self.tableView reloadData];
                        }
                        else
                        {
                        }
                    });
                }];
            }
        }
            break;
        case DWProfileSectionTypeFollowing:
        {
            if (!self.loadingNextFollowingPage) {
                
                [self.pageLoadingView startAnimating];
                self.loadingNextFollowingPage = YES;
                
                [MSUserStore loadNextPage:self.followingNextUrl withCompletion:^(NSArray *users, NSString *nextPageUrl, NSError *error) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.pageLoadingView stopAnimating];
                        self.loadingNextFollowingPage = NO;
                        
                        if (!error) {
                            self.following = [self.following arrayByAddingObjectsFromArray:users];
                            self.followingNextUrl = nextPageUrl;
                            
                            if (self.currentSection == DWProfileSectionTypeFollowing) {
                                [self.tableView reloadData];
                            }
                        }
                        else
                        {
                        }
                    });
                }];
            }
        }
            break;
        case DWProfileSectionTypeFollowers:
        {
            if (!self.loadingNextFollowersPage) {
                
                self.loadingNextFollowersPage = YES;
                [self.pageLoadingView startAnimating];
                
                [MSUserStore loadNextPage:self.followersNextUrl withCompletion:^(NSArray *users, NSString *nextPageUrl, NSError *error) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.loadingNextFollowersPage = NO;
                        [self.pageLoadingView stopAnimating];
                        
                        if (!error) {
                            self.followers = [self.followers arrayByAddingObjectsFromArray:users];
                            self.followersNextUrl = nextPageUrl;
                            
                            if (self.currentSection == DWProfileSectionTypeFollowers) {
                                [self.tableView reloadData];
                            }
                        }
                        else
                        {
                        }
                    });
                }];
            }
        }
            break;
        default:
            break;
    }
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView timelineCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MSStatus *status = [self.timeline.statuses objectAtIndex:indexPath.row];
    
    if (status.reblog) {
        
        if (status.reblog.media_attachments.count) {
            DWTimelineMediaTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TimelineMediaReblogCell"];
            cell.status = status;
            cell.delegate = self;
            
            return cell;
        }
        else
        {
            DWTimelineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TimelineReblogCell"];
            
            cell.status = status;
            cell.delegate = self;
            
            return cell;
        }
    }
    else if (status.in_reply_to_id)
    {
        if (status.media_attachments.count) {
            DWTimelineMediaTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TimelineMediaReblogCell"];
            cell.status = status;
            cell.delegate = self;
            
            return cell;
        }
        else
        {
            DWTimelineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TimelineReblogCell"];
            
            cell.status = status;
            cell.delegate = self;
            
            return cell;
        }
    }
    else
    {
        if (status.media_attachments.count) {
            
            DWTimelineMediaTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TimelineMediaCell"];
            cell.status = status;
            cell.delegate = self;
            
            return cell;
        }
        else
        {
            DWTimelineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TimelineCell"];
            
            cell.status = status;
            cell.delegate = self;
            
            return cell;
        }
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView userCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *users = self.currentSection == DWProfileSectionTypeFollowers ? self.followers : self.following;
    MSAccount *account = [users objectAtIndex:indexPath.row];
    
    DWTimelineFollowTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AccountCell"];
    cell.account = account;
    
    return cell;
}

// !!!!!!
@end
