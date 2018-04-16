//
//  DWNotificationsViewController.m
//  DireFloof
//
//  Created by John Gabelmann on 2/16/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "DWNotificationsViewController.h"
#import "Mastodon.h"
#import "DWTimelineTableViewCell.h"
#import "DWTimelineNotificationTableViewCell.h"
#import "DWTimelineFollowTableViewCell.h"
#import "DWConstants.h"
#import "DWComposeViewController.h"
#import "UIView+Supercell.h"
#import "DWProfileViewController.h"
#import "DWTimelineViewController.h"
#import "DWNotificationStore.h"
#import "UIViewController+WebNavigation.m"
#import "UIAlertController+SupportedInterfaceOrientations.h"
#import "DWNavigationViewController.h"
#import "DWAccessibilityAction.h"
#import "UIApplication+TopController.h"

@interface DWNotificationsViewController () <UITableViewDelegate, UITableViewDataSource, DWTimelineTableViewCellDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *pageLoadingView;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *deleteAllNotificationsButton;

@property (nonatomic, strong) NSMutableDictionary *cachedEstimatedHeights;

@property (nonatomic, assign) BOOL loadingNextPage;

@end

@implementation DWNotificationsViewController

#pragma mark - Actions

- (IBAction)clearNotificationsButtonPressed:(id)sender
{
    UIAlertController *confirmationController = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"Are you sure you want to clear all your notifications?", @"Are you sure you want to clear all your notifications?") preferredStyle:UIAlertControllerStyleAlert];
    [confirmationController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:nil]];
    [confirmationController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [[MSNotificationStore sharedStore] clearNotificationsWithCompletion:^(BOOL success, NSError *error) {
            
            if (success) {
                [[DWNotificationStore sharedStore] setNotificationTimeline:nil];
                [self.tableView reloadData];
            }
            else
            {
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %li", NSLocalizedString(@"Failed to clear notifications with error:", @"Failed to clear notifications with error:"), (long)error.code] preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
                [self presentViewController:alertController animated:YES completion:nil];
            }
        }];
    }]];
    
    [self presentViewController:confirmationController animated:YES completion:nil];
}


- (IBAction)scrollToTop:(id)sender
{
    if ([self.tableView numberOfRowsInSection:0]) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
}


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.cachedEstimatedHeights = [NSMutableDictionary dictionary];
    
    [self configureViews];
    [self configureData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveCleanupNotification:) name:DW_NEEDS_STATUS_CLEANUP_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveCleanupNotification:) name:DW_NEEDS_REFRESH_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearData) name:DW_DID_SWITCH_INSTANCES_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshData) name:DW_DID_SWITCH_INSTANCES_NOTIFICATION object:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[DWNotificationStore sharedStore] notificationBadge].hidden = YES;
    
    if ([[self.tableView indexPathsForVisibleRows] containsObject:[NSIndexPath indexPathForRow:0 inSection:0]]) {
        [self refreshData];
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
    [self.cachedEstimatedHeights removeAllObjects];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"ReplySegue"])
    {
        UITableViewCell *selectedCell = [sender supercell];
        
        NSIndexPath *selectedIndex = [self.tableView indexPathForCell:selectedCell];
        MSNotification *selectedNotification = [[[DWNotificationStore sharedStore] notificationTimeline].statuses objectAtIndex:selectedIndex.row];
        MSStatus *selectedStatus = selectedNotification.status;
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
        DWComposeViewController *destinationController = segue.destinationViewController;
        
        MSStatus *statusToReport = sender;
        if (statusToReport.reblog) {
            statusToReport = statusToReport.reblog;
        }
        
        destinationController.replyToStatus = statusToReport;
        destinationController.reporting = YES;
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
            MSNotification *selectedNotification = [[[DWNotificationStore sharedStore] notificationTimeline].statuses objectAtIndex:selectedIndex.row];
            
            selectedAccount = selectedNotification.account;
        }
        
        DWProfileViewController *destinationViewController = segue.destinationViewController;
        destinationViewController.account = selectedAccount;
    }
    else if ([segue.identifier isEqualToString:@"ThreadSegue"])
    {
        NSIndexPath *selectedIndex = [self.tableView indexPathForCell:sender];
        MSNotification *selectedNotification = [[[DWNotificationStore sharedStore] notificationTimeline].statuses objectAtIndex:selectedIndex.row];
        MSStatus *selectedStatus = selectedNotification.status;
        if (selectedStatus.reblog) {
            selectedStatus = selectedStatus.reblog;
        }
        
        DWTimelineViewController *destinationViewController = segue.destinationViewController;
        destinationViewController.threadStatus = selectedStatus;
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


#pragma mark - UITableView Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (![[DWNotificationStore sharedStore] notificationTimeline]) {
        return 0;
    }
    
    return [[DWNotificationStore sharedStore] notificationTimeline].statuses.count;
}


- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MSNotification *notification = [[[DWNotificationStore sharedStore] notificationTimeline].statuses objectAtIndex:indexPath.row];

    NSNumber *cachedHeight = [self.cachedEstimatedHeights objectForKey:notification._id];
    if (cachedHeight) {
        return cachedHeight.floatValue;
    }
    
    return 96.0f;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MSNotification *notification = [[[DWNotificationStore sharedStore] notificationTimeline].statuses objectAtIndex:indexPath.row];
    
    if ([notification.type isEqualToString:MS_NOTIFICATION_TYPE_FOLLOW]) {
    
        DWTimelineFollowTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"FollowCell"];
        cell.notification = notification;

        return cell;
    }
    else if ([notification.type isEqualToString:MS_NOTIFICATION_TYPE_MENTION])
    {
        DWTimelineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MentionCell"];
        cell.notification = notification;
        cell.delegate = self;
        cell.accessibilityCustomActions = [DWAccessibilityAction accessibilityActionsForStatus:notification.status atIndexPath:indexPath withTarget:self andSelector:@selector(cellAccessibilityActionSelected:)];

        return cell;
    }
    else
    {
        DWTimelineNotificationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"NotificationCell"];
        cell.notification = notification;
        cell.delegate = self;
        cell.accessibilityCustomActions = [DWAccessibilityAction accessibilityActionsForStatus:notification.status atIndexPath:indexPath withTarget:self andSelector:@selector(cellAccessibilityActionSelected:)];

        return cell;
    }
        
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    MSNotification *notification = [[[DWNotificationStore sharedStore] notificationTimeline].statuses objectAtIndex:indexPath.row];
    [self.cachedEstimatedHeights setObject:@(cell.bounds.size.height) forKey:notification._id];
    
    if (indexPath.row >= [[DWNotificationStore sharedStore] notificationTimeline].statuses.count - 10 && [[DWNotificationStore sharedStore] notificationTimeline].nextPageUrl) {
        [self loadNextPage];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (![selectedCell isKindOfClass:[DWTimelineFollowTableViewCell class]]) {
        [self performSegueWithIdentifier:@"ThreadSegue" sender:selectedCell];
    }
}


#pragma mark - DWTimelineTableViewCell Delegate Methods

- (void)timelineCell:(DWTimelineTableViewCell *)cell didDeleteStatus:(MSStatus *)status
{
    [self refreshData];
}


- (void)timelineCell:(DWTimelineTableViewCell *)cell didBlockUser:(MSAccount *)user
{
    [self refreshData];
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
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %li", NSLocalizedString(@"Failed to load user with error:", @"Failed to load user with error:"), (long)error.code] preferredStyle:UIAlertControllerStyleAlert];
            
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }];
}

- (void)timelineCell:(DWTimelineTableViewCell *)cell didSelectURL:(NSURL *)url
{
    [self openWebURL:url];
}


#pragma mark - Observers

- (void)didReceiveCleanupNotification:(NSNotification *)notification
{
    [self refreshData];
}


#pragma mark - Private Methods

- (void)configureViews
{
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
    
    self.deleteAllNotificationsButton.accessibilityLabel = NSLocalizedString(@"Delete all notifications", @"Delete all notifications");
}


- (void)configureData
{
    [self.pageLoadingView startAnimating];
    
    [[MSNotificationStore sharedStore] getNotificationsSinceId:nil withCompletion:^(BOOL success, MSTimeline *notifications, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                [self.pageLoadingView stopAnimating];
                
                [[DWNotificationStore sharedStore] setNotificationTimeline:notifications];
                [self.tableView reloadData];
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
    
    [[MSNotificationStore sharedStore] getNotificationsSinceId:nil withCompletion:^(BOOL success, MSTimeline *notifications, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
                UIRefreshControl *refreshControl = [self.tableView viewWithTag:9001];
                [refreshControl endRefreshing];
            }
            else
            {
                [self.tableView.refreshControl endRefreshing];
            }
            
            if (success) {
                [[DWNotificationStore sharedStore] setNotificationTimeline:notifications];
                [self.tableView reloadData];
            }
            else
            {
            }
        });
    }];
}



- (void)clearData
{
    [self.navigationController popToRootViewControllerAnimated:NO];
    [[DWNotificationStore sharedStore] setNotificationTimeline:nil];
    [self.tableView reloadData];
}


- (void)loadNextPage
{
    if (!self.loadingNextPage) {
        self.loadingNextPage = YES;
        [self.pageLoadingView startAnimating];
        
        [[[DWNotificationStore sharedStore] notificationTimeline] loadNextPageWithCompletion:^(BOOL success, NSError *error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.pageLoadingView stopAnimating];
                self.loadingNextPage = NO;
                
                if (success) {
                    [self.tableView reloadData];
                }
                else
                {
                }
            });
        }];
    }
}


- (BOOL)cellAccessibilityActionSelected:(DWAccessibilityAction *)sender
{
    switch (sender.actionType) {
        case DWAccessibilityActionTypeOpenHashtag:
        {
            DWTimelineViewController *hashtagController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"HashtagController"];
            hashtagController.hashtag = sender.hashtag;
            DWNavigationViewController *navController = [[DWNavigationViewController alloc] initWithRootViewController:hashtagController];
            
            [[[UIApplication sharedApplication] topController] presentViewController:navController animated:YES completion:nil];
        }
            
            return YES;
        case DWAccessibilityActionTypeOpenUser:
            [self timelineCell:nil didSelectUser:sender.user];
            return YES;
        case DWAccessibilityActionTypeOpenUrl:
            [self timelineCell:nil didSelectURL:sender.url];
            return YES;
        case DWAccessibilityActionTypeOpenThread:
            [self tableView:self.tableView didSelectRowAtIndexPath:sender.indexPath];
            return YES;
        default:
            break;
    }
    
    return NO;
}

@end
