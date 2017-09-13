//
//  DWNotificationSettingsViewController.m
//  DireFloof
//
//  Created by John Gabelmann on 3/30/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "DWNotificationSettingsViewController.h"
#import "DWSettingStore.h"
#import "DWConstants.h"
#import "DWMenuTableViewCell.h"
#import "DWNotificationStore.h"

typedef NS_ENUM(NSUInteger, DWMenuRowType) {
    DWMenuRowTypeFollowers = 0,
    DWMenuRowTypeFavorites,
    DWMenuRowTypeMentions,
    DWMenuRowTypeBoosts,
};

@interface DWNotificationSettingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSArray *menuItems;

@end

@implementation DWNotificationSettingsViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tableView.estimatedRowHeight = self.tableView.rowHeight;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    [self configureData];
    
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:UIContentSizeCategoryDidChangeNotification object:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.tableView];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


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
    DWMenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell"];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case DWMenuRowTypeBoosts:
            [[DWSettingStore sharedStore] setBoostNotifications:![[DWSettingStore sharedStore] boostNotifications]];
            break;
        case DWMenuRowTypeMentions:
            [[DWSettingStore sharedStore] setMentionNotifications:![[DWSettingStore sharedStore] mentionNotifications]];
            break;
        case DWMenuRowTypeFavorites:
            [[DWSettingStore sharedStore] setFavoriteNotifications:![[DWSettingStore sharedStore] favoriteNotifications]];
            break;
        case DWMenuRowTypeFollowers:
            [[DWSettingStore sharedStore] setNewFollowerNotifications:![[DWSettingStore sharedStore] newFollowerNotifications]];
            break;
        default:
            break;
    }
    
    [self.tableView reloadData];
    
    [[DWNotificationStore sharedStore] stopNotificationRefresh];
    [[DWNotificationStore sharedStore] registerForNotifications];
}


#pragma mark - Private Methods

- (void)configureData
{
    self.menuItems = @[NSLocalizedString(@"Receive new follower notifications", @"Receive new follower notifications"),
                       NSLocalizedString(@"Receive favorite notifications", @"Receive favorite notifications"),
                       NSLocalizedString(@"Receive mention notifications", @"Receive mention notifications"),
                       NSLocalizedString(@"Receive boost notifications", @"Receive boost notifications")];
    
    [self.tableView reloadData];
}


- (void)configureCell:(DWMenuTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    cell.titleImageView.image = nil;
    cell.titleLabel.text = [self.menuItems objectAtIndex:indexPath.row];
    cell.detailTitleLabel.text = nil;
    
    cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    cell.titleLabel.numberOfLines = 0;
    cell.detailTitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    cell.detailTitleLabel.numberOfLines = 0;
    
    cell.titleLabel.textColor = [UIColor whiteColor];
    cell.detailTitleLabel.textColor = DW_LINK_TINT_COLOR;
    
    switch (indexPath.row) {
        case DWMenuRowTypeFollowers:
            cell.accessoryType = [[DWSettingStore sharedStore] newFollowerNotifications] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        case DWMenuRowTypeFavorites:
            cell.accessoryType = [[DWSettingStore sharedStore] favoriteNotifications] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        case DWMenuRowTypeMentions:
            cell.accessoryType = [[DWSettingStore sharedStore] mentionNotifications] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        case DWMenuRowTypeBoosts:
            cell.accessoryType = [[DWSettingStore sharedStore] boostNotifications] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        default:
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
    }
}

@end
