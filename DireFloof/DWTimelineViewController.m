//
//  DWTimelineViewController.m
//  DireFloof
//
//  Created by John Gabelmann on 2/26/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "DWTimelineViewController.h"
#import "DWTimelineTableViewCell.h"
#import "DWTimelineMediaTableViewCell.h"
#import "DWConstants.h"
#import "DWComposeViewController.h"
#import "UIView+Supercell.h"
#import "DWProfileViewController.h"
#import "UIViewController+NearestNavigationController.h"
#import "DWSettingStore.h"
#import "UIViewController+WebNavigation.h"
#import "UIApplication+TopController.h"
#import "UIAlertController+SupportedInterfaceOrientations.h"

IB_DESIGNABLE
@interface DWTimelineViewController () <UITableViewDelegate, UITableViewDataSource, DWTimelineTableViewCellDelegate>

@property (nonatomic, assign) IBInspectable BOOL isPublic;
@property (nonatomic, assign) IBInspectable BOOL isLocal;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *pageLoadingView;
@property (nonatomic, weak) IBOutlet UIButton *scrollToTopButton;

@property (nonatomic, weak) IBOutlet UIBarButtonItem *publicTimelineSwitch;
@property (nonatomic, weak) IBOutlet UINavigationItem *publicTimelineNavigationItem;

@property (nonatomic, strong) MSTimeline *timeline;
@property (nonatomic, assign) BOOL loadingNextPage;

@property (nonatomic, strong) NSMutableDictionary *cachedEstimatedHeights;

@end

@implementation DWTimelineViewController

#pragma mark - Actions

- (IBAction)closeButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)scrollToTop:(id)sender
{
    if ([self.tableView numberOfRowsInSection:0]) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    
    if (!self.scrollToTopButton.hidden) {
        [self hideScrollToTopButton];
    }
}


- (IBAction)timelineSwitchPressed:(id)sender
{
    [[DWSettingStore sharedStore] setShowLocalTimeline:![[DWSettingStore sharedStore] showLocalTimeline]];
    
    if ([[DWSettingStore sharedStore] showLocalTimeline]) {
        self.publicTimelineSwitch.image = [UIImage imageNamed:@"PublicIcon"];
        self.publicTimelineSwitch.accessibilityLabel = NSLocalizedString(@"Federated timeline", @"Federated timeline");
        self.publicTimelineNavigationItem.title = NSLocalizedString(@"Local", @"Local");
    }
    else
    {
        self.publicTimelineSwitch.image = [UIImage imageNamed:@"LocalIcon"];
        self.publicTimelineSwitch.accessibilityLabel = NSLocalizedString(@"Local timeline", @"Local timeline");
        self.publicTimelineNavigationItem.title = NSLocalizedString(@"Federated", @"Federated");
    }
    
    [self.navigationController.tabBarItem setImage:[[DWSettingStore sharedStore] showLocalTimeline] ? [UIImage imageNamed:@"LocalIcon"] : [UIImage imageNamed:@"PublicIcon"]];
    [self.navigationController.tabBarItem setSelectedImage:[[DWSettingStore sharedStore] showLocalTimeline] ? [UIImage imageNamed:@"LocalIcon"] : [UIImage imageNamed:@"PublicIcon"]];
    
    [self clearData];
    [self configureData];
}


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.cachedEstimatedHeights = [NSMutableDictionary dictionary];
    
    [self configureViews];
    [self configureData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clearData) name:DW_DID_SWITCH_INSTANCES_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshData) name:DW_DID_SWITCH_INSTANCES_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveCleanupNotification:) name:DW_NEEDS_STATUS_CLEANUP_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustFonts) name:UIContentSizeCategoryDidChangeNotification object:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.favorites || self.threadStatus || self.hashtag) {
        [self.navigationController setNavigationBarHidden:NO animated:animated];
    }
    else if (!self.hashtag)
    {
        [self.navigationController setNavigationBarHidden:YES animated:animated];
    }
    
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];

}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
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


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Navigation

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
            MSStatus *selectedStatus = [self.timeline.statuses objectAtIndex:selectedIndex.row];
            
            selectedAccount = selectedStatus.reblog ? selectedStatus.reblog.account : selectedStatus.account;
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


- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"ThreadSegue"] && self.threadStatus) {
        NSIndexPath *selectedIndex = [self.tableView indexPathForCell:sender];
        MSStatus *selectedStatus = [self.timeline.statuses objectAtIndex:selectedIndex.row];
        
        if ([selectedStatus._id isEqual:self.threadStatus._id]) {
            return NO;
        }
    }
    
    return YES;
}


#pragma mark - UITableView Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (!self.timeline) {
        return 0;
    }
    
    return self.timeline.statuses.count;
}


- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MSStatus *status = [self.timeline.statuses objectAtIndex:indexPath.row];
    
    NSNumber *cachedHeight = [self.cachedEstimatedHeights objectForKey:status._id];
    if (cachedHeight) {
        return cachedHeight.floatValue;
    }
    
    return 96.0f;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MSStatus *status = [self.timeline.statuses objectAtIndex:indexPath.row];
    
    if (status.reblog && !self.threadStatus) {
        
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
    else if (status.in_reply_to_id && !self.threadStatus)
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
        BOOL isThreadStatus = NO;
        
        if (self.threadStatus) {
            isThreadStatus = [self.threadStatus._id isEqual:status._id];
        }
        
        if (status.media_attachments.count) {
            
            DWTimelineMediaTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:isThreadStatus ? @"TimelineMediaThreadCell" : @"TimelineMediaCell"];
            cell.status = status;
            cell.delegate = self;
            
            return cell;
        }
        else
        {
            DWTimelineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:isThreadStatus ? @"TimelineThreadCell" : @"TimelineCell"];
            
            cell.status = status;
            cell.delegate = self;
            
            return cell;
            
        }
    }
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    MSStatus *status = [self.timeline.statuses objectAtIndex:indexPath.row];
    [self.cachedEstimatedHeights setObject:@(cell.bounds.size.height) forKey:status._id];
    
    if (indexPath.row >= self.timeline.statuses.count - 10 && self.timeline.nextPageUrl) {
        [self loadNextPage];
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.threadStatus) {
        [self performSegueWithIdentifier:@"ThreadSegue" sender:[tableView cellForRowAtIndexPath:indexPath]];
    }
}


#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (!self.scrollToTopButton.hidden) {
        [self hideScrollToTopButton];
    }
}


#pragma mark - DWTimelineTableViewCell Delegate Methods

- (void)timelineCell:(DWTimelineTableViewCell *)cell didDeleteStatus:(MSStatus *)status
{
    [self.timeline purgeLocalStatus:status];
    [self.tableView reloadData];
    
    if (self.threadStatus) {
        if ([status._id isEqual:self.threadStatus._id]) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
}


- (void)timelineCell:(DWTimelineTableViewCell *)cell didBlockUser:(MSAccount *)user
{
    [self.timeline purgeLocalStatusesByUser:user];
    [self.tableView reloadData];
    
    if (self.threadStatus) {
        if ([user._id isEqual:self.threadStatus.account._id]) {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
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
    if ([notification.object isKindOfClass:[MSStatus class]]) {
        [self.timeline purgeLocalStatus:notification.object];
    }
    else
    {
        [self.timeline purgeLocalStatusesByUser:notification.object];
    }
    
    [self.tableView reloadData];
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
    
    if (self.hashtag) {
        self.title = [NSString stringWithFormat:@"#%@", self.hashtag];
    }
    
    if ([[DWSettingStore sharedStore] showLocalTimeline]) {
        self.publicTimelineSwitch.image = [UIImage imageNamed:@"PublicIcon"];
        self.publicTimelineSwitch.accessibilityLabel = NSLocalizedString(@"Federated timeline", @"Federated timeline");
        self.publicTimelineNavigationItem.title = NSLocalizedString(@"Local", @"Local");
    }
    else
    {
        self.publicTimelineSwitch.image = [UIImage imageNamed:@"LocalIcon"];
        self.publicTimelineSwitch.accessibilityLabel = NSLocalizedString(@"Local timeline", @"Local timeline");
        self.publicTimelineNavigationItem.title = NSLocalizedString(@"Federated", @"Federated");
    }
    
    [self.scrollToTopButton setTitle:[[DWSettingStore sharedStore] awooMode] ? NSLocalizedString(@"See new awoos", @"See new awoos") : NSLocalizedString(@"See new toots", @"See new toots") forState:UIControlStateNormal];
}


- (void)adjustFonts
{
    self.scrollToTopButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
}


- (void)configureData
{
    [self.pageLoadingView startAnimating];
    
    if (self.hashtag) {
        
        [[MSTimelineStore sharedStore] getHashtagTimelineWithHashtag:self.hashtag withCompletion:^(BOOL success, MSTimeline *timeline, NSError *error) {
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
                    BOOL firstLoad = self.timeline == nil;
                    MSStatus *firstStatus = firstLoad ? nil : self.timeline.statuses.firstObject;
                    self.timeline = timeline;
                    [self.tableView reloadData];
                    
                    if (firstLoad) {
                        [UIView setAnimationsEnabled:NO];
                        [self.tableView beginUpdates];
                        [self.tableView endUpdates];
                        [UIView setAnimationsEnabled:YES];
                    }
                    else if (firstStatus)
                    {
                        NSInteger indexOfLastStatus = [self.timeline.statuses indexOfObjectPassingTest:^BOOL(MSStatus  * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            return [obj._id isEqualToString:firstStatus._id];
                        }];
                        
                        if (indexOfLastStatus != NSNotFound) {
                            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:indexOfLastStatus inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                            
                            if (indexOfLastStatus != 0) {
                                [self showScrollToTopButton];
                            }
                        }
                    }
                }
                else
                {
                }
            });
        }];
    }
    else if (self.favorites)
    {
        [[MSTimelineStore sharedStore] getFavoriteStatusesWithCompletion:^(BOOL success, MSTimeline *favoriteStatuses, NSError *error) {
            
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
                    BOOL firstLoad = self.timeline == nil;
                    self.timeline = favoriteStatuses;
                    [self.tableView reloadData];
                    
                    if (firstLoad) {
                        [UIView setAnimationsEnabled:NO];
                        [self.tableView beginUpdates];
                        [self.tableView endUpdates];
                        [UIView setAnimationsEnabled:YES];
                    }
                }
                else
                {
                }
            });
            
        }];
    }
    else if (self.threadStatus)
    {
        [[MSTimelineStore sharedStore] getThreadForStatus:self.threadStatus withCompletion:^(BOOL success, MSTimeline *statusThread, NSError *error) {
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
                    BOOL firstLoad = self.timeline == nil;
                    self.timeline = statusThread;
                    [self.tableView reloadData];
                    
                    if (firstLoad) {
                        [UIView setAnimationsEnabled:NO];
                        [self.tableView beginUpdates];
                        [self.tableView endUpdates];
                        [UIView setAnimationsEnabled:YES];
                    }
                }
                else
                {
                }
            });
        }];
    }
    else
    {
        [[MSTimelineStore sharedStore] getTimelineForTimelineType:(self.isPublic ? ([[DWSettingStore sharedStore] showLocalTimeline] ? MSTimelineTypeLocal : MSTimelineTypePublic) : MSTimelineTypeHome) withCompletion:^(BOOL success, MSTimeline *timeline, NSError *error) {
            
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
                    BOOL firstLoad = self.timeline == nil;
                    MSStatus *firstStatus = firstLoad ? nil : self.timeline.statuses.firstObject;
                    self.timeline = timeline;
                    [self.tableView reloadData];
                    
                    if (firstLoad) {
                        [UIView setAnimationsEnabled:NO];
                        [self.tableView beginUpdates];
                        [self.tableView endUpdates];
                        [UIView setAnimationsEnabled:YES];
                    }
                    else if (firstStatus)
                    {
                        NSInteger indexOfLastStatus = [self.timeline.statuses indexOfObjectPassingTest:^BOOL(MSStatus  * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                            return [obj._id isEqualToString:firstStatus._id];
                        }];
                        
                        if (indexOfLastStatus != NSNotFound) {
                            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:indexOfLastStatus inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
                            
                            if (indexOfLastStatus != 0) {
                                [self showScrollToTopButton];
                            }
                        }
                    }
                }
                else
                {
                }
            });
        }];
    }
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


- (void)clearData
{
    [self.navigationController popToRootViewControllerAnimated:NO];
    self.timeline = nil;
    [self.tableView reloadData];
}


- (void)loadNextPage
{
    if (!self.loadingNextPage) {
        self.loadingNextPage = YES;
        [self.pageLoadingView startAnimating];
        
        [self.timeline loadNextPageWithCompletion:^(BOOL success, NSError *error) {
            
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


- (void)showScrollToTopButton {
    
    if (!self.scrollToTopButton.hidden) {
        return;
    }
    
    self.scrollToTopButton.alpha = 0.0f;
    self.scrollToTopButton.hidden = NO;
    
    [UIView animateWithDuration:0.7f animations:^{
        self.scrollToTopButton.alpha = 1.0f;
    }];
}


- (void)hideScrollToTopButton {
    
    [UIView animateWithDuration:0.35f animations:^{
        self.scrollToTopButton.alpha = 0.0f;
    } completion:^(BOOL finished) {
        self.scrollToTopButton.hidden = YES;
    }];
}

// !
@end
