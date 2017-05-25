//
//  DWBlockedUsersViewController.m
//  DireFloof
//
//  Created by John Gabelmann on 2/28/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "DWBlockedUsersViewController.h"
#import "DWTimelineFollowTableViewCell.h"
#import "DWProfileViewController.h"
#import "Mastodon.h"
#import "UIView+Supercell.h"
#import "DWConstants.h"
#import "DWMenuTableViewCell.h"

@interface DWBlockedUsersViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *pageLoadingView;

@property (nonatomic, strong) NSArray *blockedUsers;

@property (nonatomic, assign) BOOL loadingNextPage;
@property (nonatomic, strong) NSString *nextPageUrl;
@end

@implementation DWBlockedUsersViewController

#pragma mark - Actions

- (IBAction)unblockDomain:(id)sender
{
    UITableViewCell *selectedCell = [sender supercell];
    NSIndexPath *selectedIndex = [self.tableView indexPathForCell:selectedCell];
    
    NSString *selectedDomain = [self.blockedUsers objectAtIndex:selectedIndex.row];
    
    [[MSAppStore sharedStore] unblockMastodonInstance:selectedDomain withCompletion:^(BOOL success, NSError *error) {
        if (success) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.blockedUsers = [self.blockedUsers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"NOT SELF LIKE[cd] %@", selectedDomain]];
                [self.tableView reloadData];
            });
        }
        else
        {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Failed to unblock domain with error:", @"Failed to block domain with error:"), error.localizedFailureReason] preferredStyle:UIAlertControllerStyleAlert];
            
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self configureViews];
    [self configureData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    if (self.requests) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(requestRespondedNotification:) name:DW_DID_ANSWER_FOLLOW_REQUEST_NOTIFICATION object:nil];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self.tableView];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"ProfileSegue"])
    {
        UITableViewCell *selectedCell = [sender supercell];
        
        NSIndexPath *selectedIndex = [self.tableView indexPathForCell:selectedCell];
        
        MSAccount *selectedAccount = [self.blockedUsers objectAtIndex:selectedIndex.row];
        
        DWProfileViewController *destinationViewController = segue.destinationViewController;
        destinationViewController.account = selectedAccount;
    }
}


#pragma mark - UITableView Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.blockedUsers ? self.blockedUsers.count : 0;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.domains ? [self tableView:tableView domainCellForRowAtIndexPath:indexPath] : [self tableView:tableView userCellForRowAtIndexPath:indexPath];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.domains) {
        [self performSegueWithIdentifier:@"ProfileSegue" sender:[tableView cellForRowAtIndexPath:indexPath]];
    }
}


- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= self.blockedUsers.count - 10 && self.nextPageUrl) {
        [self loadNextPage];
    }
    
}


#pragma mark - Observers

- (void)requestRespondedNotification:(NSNotification *)notification
{
    NSIndexPath *selectedIndex = [self.tableView indexPathForCell:notification.object];
    NSMutableArray *mutableBlockedUsers = [self.blockedUsers mutableCopy];
    [mutableBlockedUsers removeObjectAtIndex:selectedIndex.row];
    self.blockedUsers = mutableBlockedUsers;
    [self.tableView reloadData];
}


#pragma mark - Private Methods

- (void)configureViews
{
    if (self.mutes) {
        self.title = NSLocalizedString(@"Muted users", @"Muted users");
    }
    else if (self.requests)
    {
        self.title = NSLocalizedString(@"Follow requests", @"Follow requests");
    }
    else if (self.domains)
    {
        self.title = NSLocalizedString(@"Blocked domains", @"Blocked domains");
    }
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 96.0f;
    
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
}


- (void)configureData
{
    [self.pageLoadingView startAnimating];
    
    if (self.mutes) {
        [[MSUserStore sharedStore] getMutedUsersWithCompletion:^(BOOL success, NSArray *blockedUsers, NSString *nextPageUrl, NSError *error) {
            if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
                UIRefreshControl *refreshControl = [self.tableView viewWithTag:9001];
                [refreshControl endRefreshing];
            }
            else
            {
                [self.tableView.refreshControl endRefreshing];
            }
            
            if (success) {
                
                [self.pageLoadingView stopAnimating];
                self.blockedUsers = blockedUsers;
                self.nextPageUrl = nextPageUrl;
                
                [self.tableView reloadData];
            }
        }];
    }
    else if (self.requests)
    {
        [[MSUserStore sharedStore] getFollowRequestUsersWithCompletion:^(BOOL success, NSArray *requests, NSString *nextPageUrl, NSError *error) {
            if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
                UIRefreshControl *refreshControl = [self.tableView viewWithTag:9001];
                [refreshControl endRefreshing];
            }
            else
            {
                [self.tableView.refreshControl endRefreshing];
            }
            
            if (success) {
                
                [self.pageLoadingView stopAnimating];
                self.blockedUsers = requests;
                self.nextPageUrl = nextPageUrl;
                
                [self.tableView reloadData];
            }
        }];
    }
    else if (self.domains)
    {
        [[MSAppStore sharedStore] getBlockedInstancesWithCompletion:^(BOOL success, NSArray *instances, NSString *nextPageUrl, NSError *error) {
            if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
                UIRefreshControl *refreshControl = [self.tableView viewWithTag:9001];
                [refreshControl endRefreshing];
            }
            else
            {
                [self.tableView.refreshControl endRefreshing];
            }
            
            if (success) {
                
                [self.pageLoadingView stopAnimating];
                self.blockedUsers = instances;
                self.nextPageUrl = nextPageUrl;
                
                [self.tableView reloadData];
            }
        }];
    }
    else
    {
        [[MSUserStore sharedStore] getBlockedUsersWithCompletion:^(BOOL success, NSArray *blockedUsers, NSString *nextPageUrl, NSError *error) {
            
            if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
                UIRefreshControl *refreshControl = [self.tableView viewWithTag:9001];
                [refreshControl endRefreshing];
            }
            else
            {
                [self.tableView.refreshControl endRefreshing];
            }
            
            if (success) {
                
                [self.pageLoadingView stopAnimating];
                self.blockedUsers = blockedUsers;
                self.nextPageUrl = nextPageUrl;
                
                [self.tableView reloadData];
            }
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


- (void)loadNextPage
{
    if (!self.loadingNextPage) {
        
        self.loadingNextPage = YES;
        [self.pageLoadingView startAnimating];
        
        [MSUserStore loadNextPage:self.nextPageUrl withCompletion:^(NSArray *users, NSString *nextPageUrl, NSError *error) {
            
            self.loadingNextPage = NO;
            [self.pageLoadingView stopAnimating];
            
            if (!error) {
                self.blockedUsers = [self.blockedUsers arrayByAddingObjectsFromArray:users];
                self.nextPageUrl = nextPageUrl;
                
                [self.tableView reloadData];
            }
            else
            {
            }
        }];
    }
}


- (UITableViewCell *)tableView:(UITableView *)tableView userCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MSAccount *account = [self.blockedUsers objectAtIndex:indexPath.row];
    
    DWTimelineFollowTableViewCell *cell = self.requests ? [tableView dequeueReusableCellWithIdentifier:@"AccountRequestCell"] : [tableView dequeueReusableCellWithIdentifier:@"AccountCell"];
    
    cell.showMuteStatus = self.mutes;
    cell.isRequest = self.requests;
    
    cell.account = account;
    
    return cell;
}


- (UITableViewCell *)tableView:(UITableView *)tableView domainCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *domain = [self.blockedUsers objectAtIndex:indexPath.row];
    
    DWMenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DomainCell"];
    
    cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    cell.titleLabel.numberOfLines = 0;
    cell.titleLabel.textColor = [UIColor whiteColor];
    
    cell.titleLabel.text = domain;

    return cell;
}

@end
