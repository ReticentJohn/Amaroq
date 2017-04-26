//
//  DWInstancesViewController.m
//  DireFloof
//
//  Created by John Gabelmann on 4/20/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "DWInstancesViewController.h"
#import "Mastodon.h"
#import "DWConstants.h"
#import "DWMenuTableViewCell.h"

@interface DWInstancesViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, assign) BOOL isSwitchingInstances;

@end

@implementation DWInstancesViewController

#pragma mark

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.estimatedRowHeight = self.tableView.rowHeight;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.title = NSLocalizedString(@"My instances", @"My instances");
    
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:UIContentSizeCategoryDidChangeNotification object:nil];

    
    [self.tableView reloadData];
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
    return [[[MSAppStore sharedStore] availableInstances] count] + 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DWMenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell"];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isSwitchingInstances) {
        return;
    }
    
    if (indexPath.row >= [[[MSAppStore sharedStore] availableInstances] count]) {
        [[MSAuthStore sharedStore] requestAddInstanceAccount];
    }
    else
    {
        NSDictionary *availableInstance = [[[MSAppStore sharedStore] availableInstances] objectAtIndex:indexPath.row];
        
        self.isSwitchingInstances = YES;
        
        [[MSAuthStore sharedStore] switchToInstance:[availableInstance objectForKey:MS_INSTANCE_KEY] withCompletion:^(BOOL success) {
            self.isSwitchingInstances = NO;
            [self.tableView reloadData];
            [[NSNotificationCenter defaultCenter] postNotificationName:DW_DID_SWITCH_INSTANCES_NOTIFICATION object:nil];
        }];
    }
    
}


#pragma mark - Private Methods

- (void)configureCell:(DWMenuTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    NSString *instanceItem = @"";
    
    if (indexPath.row >= [[[MSAppStore sharedStore] availableInstances] count]) {
        instanceItem = NSLocalizedString(@"Add instance", @"Add instance");
        
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    else
    {
        NSDictionary *availableInstance = [[[MSAppStore sharedStore] availableInstances] objectAtIndex:indexPath.row];
        
        instanceItem = [availableInstance objectForKey:MS_INSTANCE_KEY];
        
        cell.accessoryType = [[[MSAppStore sharedStore] instance] isEqualToString:instanceItem] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    cell.titleImageView.image = nil;
    cell.titleLabel.text = instanceItem;
    cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    cell.titleLabel.numberOfLines = 0;
    cell.detailTitleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    cell.detailTitleLabel.numberOfLines = 0;
    
    cell.titleLabel.textColor = [UIColor whiteColor];
}


@end
