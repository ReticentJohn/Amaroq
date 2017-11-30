//
//  DWAppSettingsViewController.m
//  DireFloof
//
//  Created by John Gabelmann on 3/8/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "DWAppSettingsViewController.h"
#import "DWSettingStore.h"
#import "DWConstants.h"
#import "DWMenuTableViewCell.h"

#define DW_MENU_ITEM_TITLE_KEY @"title"
#define DW_MENU_ITEM_SUB_KEY   @"subtitle"
#define DW_MENU_ITEM_IMAGE_KEY @"image"

typedef NS_ENUM(NSUInteger, DWMenuRowType) {
    DWMenuRowTypeNotifications = 0,
    DWMenuRowTypePrivate,
    DWMenuRowTypePublic,
    DWMenuRowTypeAwoo,
    DWMenuRowTypeGif,
    DWMenuRowTypeCache,
};

@interface DWAppSettingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSArray *menuItems;

@end

@implementation DWAppSettingsViewController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tableView.estimatedRowHeight = self.tableView.rowHeight;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    [self configureData];
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
        case DWMenuRowTypePrivate:
            [[DWSettingStore sharedStore] setAlwaysPrivate:![[DWSettingStore sharedStore] alwaysPrivate]];
            break;
        case DWMenuRowTypePublic:
            [[DWSettingStore sharedStore] setAlwaysPublic:![[DWSettingStore sharedStore] alwaysPublic]];
            break;
        case DWMenuRowTypeAwoo:
            [[DWSettingStore sharedStore] setAwooMode:![[DWSettingStore sharedStore] awooMode]];
            break;
        case DWMenuRowTypeGif:
            [[DWSettingStore sharedStore] setDisableGifPlayback:![[DWSettingStore sharedStore] disableGifPlayback]];
            break;
        case DWMenuRowTypeCache:
            [[DWSettingStore sharedStore] purgeCaches];
            break;
        case DWMenuRowTypeNotifications:
            [self performSegueWithIdentifier:@"NotificationSegue" sender:[tableView cellForRowAtIndexPath:indexPath]];
            break;
        default:
            break;
    }
    
    [self.tableView reloadData];
}


#pragma mark - Private Methods

- (void)configureData
{
    self.menuItems = @[@{DW_MENU_ITEM_IMAGE_KEY:[UIImage imageNamed:@"NotificationsIcon"], DW_MENU_ITEM_TITLE_KEY:NSLocalizedString(@"Notification settings", @"Notification settings"), DW_MENU_ITEM_SUB_KEY:NSLocalizedString(@"Change how you receive push notifications", @"Change how you receive push notifications")},
                       @{DW_MENU_ITEM_IMAGE_KEY:[UIImage imageNamed:@"PrivateIcon"], DW_MENU_ITEM_TITLE_KEY:NSLocalizedString(@"Default posts to followers-only", @"Default posts to followers-only"), DW_MENU_ITEM_SUB_KEY:NSLocalizedString(@"Only show to followers", @"Only show to followers")},
                       @{DW_MENU_ITEM_IMAGE_KEY:[UIImage imageNamed:@"PublicIcon"], DW_MENU_ITEM_TITLE_KEY:NSLocalizedString(@"Default posts to public", @"Default posts to public"), DW_MENU_ITEM_SUB_KEY:NSLocalizedString(@"Shows on local/federated timelines", @"Shows on local/federated timelines")},
                       @{DW_MENU_ITEM_IMAGE_KEY:[UIImage imageNamed:@"AwooIcon"], DW_MENU_ITEM_TITLE_KEY:NSLocalizedString(@"Egg mode", @"Egg mode"), DW_MENU_ITEM_SUB_KEY:NSLocalizedString(@"DON'T EGG $350 PENALTY", @"DON'T EGG $350 PENALTY")},
                       @{DW_MENU_ITEM_IMAGE_KEY:[UIImage imageNamed:@"ImageIcon"], DW_MENU_ITEM_TITLE_KEY:NSLocalizedString(@"Disable gif auto-playback", @"Disable gif auto-playback"), DW_MENU_ITEM_SUB_KEY:NSLocalizedString(@"This can help older devices", @"This can help older devices")},
                       @{DW_MENU_ITEM_IMAGE_KEY:[UIImage imageNamed:@"DeleteIcon"], DW_MENU_ITEM_TITLE_KEY:NSLocalizedString(@"Clear cache", @"Clear cache"), DW_MENU_ITEM_SUB_KEY:@""}];
    
    [self.tableView reloadData];
}


- (void)configureCell:(DWMenuTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *menuItem = [self.menuItems objectAtIndex:indexPath.row];
    cell.titleImageView.image = [menuItem objectForKey:DW_MENU_ITEM_IMAGE_KEY];
    cell.titleLabel.text = [menuItem objectForKey:DW_MENU_ITEM_TITLE_KEY];
    
    cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    cell.titleLabel.numberOfLines = 0;
    cell.detailTitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    cell.detailTitleLabel.numberOfLines = 0;
    
    cell.titleLabel.textColor = [UIColor whiteColor];
    cell.detailTitleLabel.textColor = DW_LINK_TINT_COLOR;
    
    if (indexPath.row == DWMenuRowTypeCache) {
        cell.detailTitleLabel.text = [[DWSettingStore sharedStore] cacheSizeString];
    }
    else if (indexPath.row == DWMenuRowTypeNotifications)
    {
        cell.detailTitleLabel.text = nil;
    }
    else
    {
        cell.detailTitleLabel.text = [menuItem objectForKey:DW_MENU_ITEM_SUB_KEY];
    }
    
    switch (indexPath.row) {
        case DWMenuRowTypePrivate:
            cell.accessoryType = [[DWSettingStore sharedStore] alwaysPrivate] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        case DWMenuRowTypePublic:
            cell.accessoryType = [[DWSettingStore sharedStore] alwaysPublic] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        case DWMenuRowTypeAwoo:
            cell.accessoryType = [[DWSettingStore sharedStore] awooMode] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        case DWMenuRowTypeGif:
            cell.accessoryType = [[DWSettingStore sharedStore] disableGifPlayback] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
            break;
        case DWMenuRowTypeNotifications:
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        default:
            cell.accessoryType = UITableViewCellAccessoryNone;
            break;
    }
}

@end
