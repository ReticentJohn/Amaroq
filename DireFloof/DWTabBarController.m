//
//  DWTabBarController.m
//  DireFloof
//
//  Created by John Gabelmann on 2/14/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <PureLayout/PureLayout.h>
#import "DWTabBarController.h"
#import "Mastodon.h"
#import "DWNotificationStore.h"
#import "DWConstants.h"
#import "DWTimelineViewController.h"
#import "DWNotificationsViewController.h"
#import "DWAppearanceProxies.h"

typedef NS_ENUM(NSUInteger, DWTabItem) {
    DWTabItemHome = 0,
    DWTabItemLocal,
    DWTabItemFederated,
    DWTabItemNotifications,
    DWTabItemMenu,
};

@interface DWTabBarController ()
@property (nonatomic, strong) UIView *notificationBadge;

@property (nonatomic, assign) NSUInteger previousSelectedIndex;

@end

@implementation DWTabBarController

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self configureViews];
    
    self.previousSelectedIndex = 0;
    
    [[DWNotificationStore sharedStore] setNotificationBadge:self.notificationBadge];
    [[DWNotificationStore sharedStore] registerForNotifications];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Refresh the current user
    [[MSUserStore sharedStore] getCurrentUserWithCompletion:nil];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DW_WILL_PURGE_CACHE_NOTIFICATION object:nil];
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


- (BOOL)shouldAutorotate
{
    return NO;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation
/*
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}*/


- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    NSUInteger index = [tabBar.items indexOfObject:item];

    if (self.previousSelectedIndex == index) {
        
        if (index == DWTabItemHome || index == DWTabItemLocal || index == DWTabItemFederated) {
            
            DWTimelineViewController *currentController = [self.viewControllers objectAtIndex:index];
            [currentController scrollToTop:nil];
        }
        else if (index == DWTabItemNotifications)
        {
            DWNotificationsViewController *currentController = [self.viewControllers objectAtIndex:index];
            [currentController scrollToTop:nil];
        }
    }
    else
    {
        self.previousSelectedIndex = index;
        [[NSNotificationCenter defaultCenter] postNotificationName:DW_WILL_PURGE_CACHE_NOTIFICATION object:nil];
        [[self.viewControllers objectAtIndex:index] viewDidAppear:NO];
    }
}


- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    if (self.presentedViewController || ![self.view viewWithTag:1337])
    {
        [super dismissViewControllerAnimated:flag completion:completion];
    }
}


#pragma mark - Private Methods

- (void)configureViews
{
    if (!self.notificationBadge) {
        self.notificationBadge = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        self.notificationBadge.clipsToBounds = YES;
        self.notificationBadge.layer.cornerRadius = 5.0f;
        self.notificationBadge.backgroundColor = DW_BLUE_COLOR;
        self.notificationBadge.hidden = YES;
        self.notificationBadge.userInteractionEnabled = NO;
        
        [self.tabBar addSubview:self.notificationBadge];
        
        [self.notificationBadge autoSetDimensionsToSize:CGSizeMake(10, 10)];
        [self.notificationBadge autoAlignAxis:ALAxisVertical toSameAxisOfView:self.tabBar withOffset:8.0f + self.tabBar.bounds.size.width/5.0f];
        [self.notificationBadge autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.tabBar withOffset:-15.0f];
    }
}

@end
