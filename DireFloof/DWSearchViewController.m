//
//  DWSearchViewController.m
//  DireFloof
//
//  Created by John Gabelmann on 2/26/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <AFNetworking/UIImageView+AFNetworking.h>
#import "DWSearchViewController.h"
#import "DWSearchTableViewCell.h"
#import "Mastodon.h"
#import "DWConstants.h"
#import "DWTimelineViewController.h"
#import "DWProfileViewController.h"
#import "DWSettingStore.h"
#import "UIApplication+TopController.h"

typedef NS_ENUM(NSUInteger, DWSearchSectionType) {
    DWSearchSectionTypeAccounts          = 0,
    DWSearchSectionTypeHashtags          = 1,
};

@interface DWSearchViewController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UISearchBar *searchBar;
@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *accountSearchResults;
@property (nonatomic, strong) NSArray *hashtagSearchResults;

@end

@implementation DWSearchViewController

#pragma mark - Actions

- (IBAction)closeButtonPressed:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.searchBar.text.length) {
        [self.searchBar becomeFirstResponder];
    }
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
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"HashtagSegue"]) {
        
        NSIndexPath *selectedIndex = [self.tableView indexPathForCell:sender];
        NSString *selectedHashtag = [[self.hashtagSearchResults objectAtIndex:selectedIndex.row] copy];
        
        DWTimelineViewController *destinationViewController = segue.destinationViewController;
        destinationViewController.hashtag = selectedHashtag;
    }
    else if ([segue.identifier isEqualToString:@"ProfileSegue"])
    {
        NSIndexPath *selectedIndex = [self.tableView indexPathForCell:sender];
        MSAccount *selectedAccount = [self.accountSearchResults objectAtIndex:selectedIndex.row];
    
        DWProfileViewController *destinationViewController = segue.destinationViewController;
        destinationViewController.account = selectedAccount;
    }
}


#pragma mark - UISearchBar Delegate Methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    [self searchWithQuery:[searchBar.text stringByReplacingOccurrencesOfString:@"#" withString:@""]];
}


#pragma mark - UITableView Delegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    NSInteger numberOfSections = 0;
    
    numberOfSections = self.hashtagSearchResults.count > 0 ? numberOfSections + 1 : numberOfSections;
    numberOfSections = self.accountSearchResults.count > 0 || numberOfSections > 0 ? numberOfSections + 1 : numberOfSections;
    
    return numberOfSections;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case DWSearchSectionTypeAccounts:
            return self.accountSearchResults.count;
            break;
        case DWSearchSectionTypeHashtags:
            return self.hashtagSearchResults.count;
            break;
        default:
            break;
    }
    
    return 0;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case DWSearchSectionTypeAccounts:
            return NSLocalizedString(@"ACCOUNT", @"ACCOUNT");
            break;
        case DWSearchSectionTypeHashtags:
            return NSLocalizedString(@"HASHTAG", @"HASHTAG");
        default:
            break;
    }
    
    return nil;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == DWSearchSectionTypeAccounts) {
        
        DWSearchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AccountCell"];
        
        [self configureAccountCell:cell atIndexPath:indexPath];
        
        return cell;
    }
    else
    {
        DWSearchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"HashtagCell"];
        
        [self configureHashtagCell:cell atIndexPath:indexPath];
        
        return cell;
    }
}


- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    [[(UITableViewHeaderFooterView *)view contentView] setBackgroundColor:DW_SEARCH_HEADER_BACKGROUND_COLOR];
    [[(UITableViewHeaderFooterView *)view textLabel] setFont:[UIFont fontWithName:@"Roboto-Medium" size:13.0f]];
    [[(UITableViewHeaderFooterView *)view textLabel] setTextColor:DW_BACKGROUND_COLOR];
}


#pragma mark - Private Methods

- (void)configureAccountCell:(DWSearchTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    MSAccount *account = [self.accountSearchResults objectAtIndex:indexPath.row];
    
    [cell.avatarImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[[DWSettingStore sharedStore] disableGifPlayback] ? account.avatar_static : account.avatar]] placeholderImage:nil success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
        cell.avatarImageView.image = image;
        if ([[DWSettingStore sharedStore] disableGifPlayback]) {
            [cell.avatarImageView stopAnimating];
        }
    } failure:nil];
    
    if (account.display_name) {
        cell.displayNameLabel.text = account.display_name.length ? account.display_name : account.username;
    }
    
    if (account.acct) {
        cell.usernameLabel.text = [NSString stringWithFormat:@"@%@", account.acct];
    }
}


- (void)configureHashtagCell:(DWSearchTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSString *hashtag = [self.hashtagSearchResults objectAtIndex:indexPath.row];
    
    cell.displayNameLabel.text = [NSString stringWithFormat:@"#%@", hashtag];
}


- (void)searchWithQuery:(NSString *)query
{
    self.hashtagSearchResults = @[query];
    self.accountSearchResults = @[];
    [self.tableView reloadData];
    
    [[MSUserStore sharedStore] searchForUsersWithQuery:query withCompletion:^(BOOL success, NSArray *users, NSError *error) {
        
        if (success) {
            
            self.accountSearchResults = users;
            [self.tableView reloadData];
        }
        else
        {
        }
    }];
}

@end
