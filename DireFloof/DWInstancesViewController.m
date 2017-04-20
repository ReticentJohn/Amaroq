//
//  DWInstancesViewController.m
//  DireFloof
//
//  Created by John Gabelmann on 4/20/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//

#import "DWInstancesViewController.h"
#import "Mastodon.h"

@interface DWInstancesViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation DWInstancesViewController

#pragma mark

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tableView.estimatedRowHeight = self.tableView.rowHeight;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    self.title = NSLocalizedString(@"My instances", @"My instances");
    
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MenuCell"];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row >= [[[MSAppStore sharedStore] availableInstances] count]) {
        [[MSAuthStore sharedStore] requestAddInstanceAccount];
    }
    else
    {
        NSDictionary *availableInstance = [[[MSAppStore sharedStore] availableInstances] objectAtIndex:indexPath.row];
        
        [[MSAuthStore sharedStore] switchToInstance:[availableInstance objectForKey:MS_INSTANCE_KEY] withCompletion:^(BOOL success) {
            [self.tableView reloadData];
        }];
    }
    
}


#pragma mark - Private Methods

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
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
    
    cell.imageView.image = nil;
    cell.textLabel.text = instanceItem;
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    cell.detailTextLabel.numberOfLines = 0;
    
    cell.textLabel.textColor = [UIColor whiteColor];
}


@end
