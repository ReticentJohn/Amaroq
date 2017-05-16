//
//  DWMenuViewController.m
//  DireFloof
//
//  Created by John Gabelmann on 2/28/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <PureLayout/PureLayout.h>
#import "DWMenuViewController.h"
#import "DWProfileViewController.h"
#import "DWTimelineViewController.h"
#import "Mastodon.h"
#import "DWNotificationStore.h"
#import "DWBlockedUsersViewController.h"
#import "DWConstants.h"
#import "DWMenuTableViewCell.h"
#import "UIViewController+WebNavigation.h"

#define DW_MENU_ITEM_TITLE_KEY @"title"
#define DW_MENU_ITEM_IMAGE_KEY @"image"

typedef NS_ENUM(NSUInteger, DWMenuRowType) {
    DWMenuRowTypeProfile        = 0,
    DWMenuRowTypeInstances,
    DWMenuRowTypePreferences,
    DWMenuRowTypeAppSettings,
    DWMenuRowTypeFavorites,
    DWMenuRowTypeFollowRequests,
    DWMenuRowTypeBlocked,
    DWMenuRowTypeMuted,
    DWMenuRowTypeAppInformation,
    DWMenuRowTypeInformation,
    DWMenuRowTypeLogout,
};

@interface DWMenuViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *menuItems;

@end

@implementation DWMenuViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self configureData];
    
    self.tableView.estimatedRowHeight = self.tableView.rowHeight;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:UIContentSizeCategoryDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:DW_DID_SWITCH_INSTANCES_NOTIFICATION object:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.tableView];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"ProfileSegue"]) {
        
        DWProfileViewController *destinationViewController = segue.destinationViewController;
        destinationViewController.account = [[MSUserStore sharedStore] currentUser];
    }
    else if ([segue.identifier isEqualToString:@"FavoriteSegue"])
    {
        DWTimelineViewController *destinationViewController = segue.destinationViewController;
        destinationViewController.favorites = YES;
    }
    else if ([segue.identifier isEqualToString:@"BlockedSegue"])
    {
        DWBlockedUsersViewController *destinationViewController = segue.destinationViewController;
        destinationViewController.mutes = [[self.tableView indexPathForCell:sender] row] == DWMenuRowTypeMuted;
        destinationViewController.requests = [[self.tableView indexPathForCell:sender] row] == DWMenuRowTypeFollowRequests;
    }
}


- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([identifier isEqualToString:@"AboutSegue"]) {
        return  [[self.tableView indexPathForCell:sender] row] == DWMenuRowTypeAppInformation;
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
    return self.menuItems.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DWMenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:(indexPath.row == DWMenuRowTypeAppInformation || indexPath.row == DWMenuRowTypeInstances) ? @"AppCell" : @"MenuCell"];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case DWMenuRowTypeProfile:
        {
            if ([[MSUserStore sharedStore] currentUser]) {
                [self performSegueWithIdentifier:@"ProfileSegue" sender:[tableView cellForRowAtIndexPath:indexPath]];
            }
            else
            {
                [[MSUserStore sharedStore] getCurrentUserWithCompletion:^(BOOL success, MSAccount *user, NSError *error) {
                    if (success) {
                        [self performSegueWithIdentifier:@"ProfileSegue" sender:[tableView cellForRowAtIndexPath:indexPath]];
                    }
                    else
                    {
                        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Failed to retrieve your profile with error:", @"Failed to retrieve your profile with error:"), error.localizedFailureReason] preferredStyle:UIAlertControllerStyleAlert];
                        
                        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
                        
                        [self presentViewController:alertController animated:YES completion:nil];
                    }
                }];
            }
        }
            break;
        case DWMenuRowTypeInstances:
            [self performSegueWithIdentifier:@"InstanceSegue" sender:[tableView cellForRowAtIndexPath:indexPath]];
            break;
        case DWMenuRowTypePreferences:
            [[MSAuthStore sharedStore] requestPreferences];
            break;
        case DWMenuRowTypeAppSettings:
            [self performSegueWithIdentifier:@"AppSegue" sender:[tableView cellForRowAtIndexPath:indexPath]];
            break;
        case DWMenuRowTypeFavorites:
            [self performSegueWithIdentifier:@"FavoriteSegue" sender:[tableView cellForRowAtIndexPath:indexPath]];
            break;
        case DWMenuRowTypeBlocked:
        case DWMenuRowTypeMuted:
        case DWMenuRowTypeFollowRequests:
            [self performSegueWithIdentifier:@"BlockedSegue" sender:[tableView cellForRowAtIndexPath:indexPath]];
            break;
        case DWMenuRowTypeInformation:
        {
            [self openWebURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@about/more", [[MSAppStore sharedStore] base_url_string]]]];
        }
            break;
        case DWMenuRowTypeLogout:
            [[MSAuthStore sharedStore] logout];
            break;
        default:
            break;
    }
}


#pragma mark - Private Methods

- (void)configureData
{
    self.menuItems = @[@{DW_MENU_ITEM_IMAGE_KEY:[UIImage imageNamed:@"UserIcon"], DW_MENU_ITEM_TITLE_KEY:NSLocalizedString(@"My profile", @"My profile")},
                       @{DW_MENU_ITEM_IMAGE_KEY:[UIImage imageNamed:@"PublicIcon"], DW_MENU_ITEM_TITLE_KEY:NSLocalizedString(@"My instances", @"My instances")},
                       @{DW_MENU_ITEM_IMAGE_KEY:[UIImage imageNamed:@"SettingsIcon"], DW_MENU_ITEM_TITLE_KEY:NSLocalizedString(@"Account preferences", @"Account preferences")},
                       @{DW_MENU_ITEM_IMAGE_KEY:[UIImage imageNamed:@"SettingsIcon"], DW_MENU_ITEM_TITLE_KEY:NSLocalizedString(@"App settings", @"App settings")},
                       @{DW_MENU_ITEM_IMAGE_KEY:[UIImage imageNamed:@"FavoriteIcon"], DW_MENU_ITEM_TITLE_KEY:NSLocalizedString(@"Favorites", @"Favorites")},
                       @{DW_MENU_ITEM_IMAGE_KEY:[UIImage imageNamed:@"LocalIcon"], DW_MENU_ITEM_TITLE_KEY:NSLocalizedString(@"Follow requests", @"Follow requests")},
                       @{DW_MENU_ITEM_IMAGE_KEY:[UIImage imageNamed:@"BlockIcon"], DW_MENU_ITEM_TITLE_KEY:NSLocalizedString(@"Blocked users", @"Blocked users")},
                       @{DW_MENU_ITEM_IMAGE_KEY:[UIImage imageNamed:@"MuteIcon"], DW_MENU_ITEM_TITLE_KEY:NSLocalizedString(@"Muted users", @"Muted users")},
                       @{DW_MENU_ITEM_IMAGE_KEY:[UIImage imageNamed:@"DireWolfLogoSmall"], DW_MENU_ITEM_TITLE_KEY:NSLocalizedString(@"About Amaroq", @"About Amaroq")},
                       @{DW_MENU_ITEM_IMAGE_KEY:[UIImage imageNamed:@"InformationIcon"], DW_MENU_ITEM_TITLE_KEY:NSLocalizedString(@"About your Mastodon instance", @"About your Mastodon instance")},
                       @{DW_MENU_ITEM_IMAGE_KEY:[UIImage imageNamed:@"LogoutIcon"], DW_MENU_ITEM_TITLE_KEY:NSLocalizedString(@"Logout", @"Logout")}];
    
    [self.tableView reloadData];
}


- (void)configureCell:(DWMenuTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *menuItem = [self.menuItems objectAtIndex:indexPath.row];
    cell.titleImageView.image = nil;
    cell.titleImageView.image = [menuItem objectForKey:DW_MENU_ITEM_IMAGE_KEY];
    
    cell.titleLabel.text = [menuItem objectForKey:DW_MENU_ITEM_TITLE_KEY];
    
    cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    cell.titleLabel.numberOfLines = 0;
    cell.detailTitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    cell.detailTitleLabel.numberOfLines = 0;

    cell.titleLabel.textColor = [UIColor whiteColor];
    cell.detailTitleLabel.textColor = DW_LINK_TINT_COLOR;
    
    if (indexPath.row == DWMenuRowTypeAppInformation) {
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *buildVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        
        cell.detailTitleLabel.text = [NSString stringWithFormat:@"v%@ (%@)", appVersion, buildVersion];
    }
    else if (indexPath.row == DWMenuRowTypeInstances)
    {
        cell.detailTitleLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Currently logged into:", @"Currently logged into:"), [[MSAppStore sharedStore] instance]];
    }
}

@end
