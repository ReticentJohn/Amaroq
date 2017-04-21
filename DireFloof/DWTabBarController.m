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
@property (nonatomic, strong) UIView *centerTabOverlay;

@property (nonatomic, assign) NSUInteger previousSelectedIndex;

@end

@implementation DWTabBarController

#pragma mark - Actions

- (void)composeButtonPressed
{
    [self performSegueWithIdentifier:@"ComposeSegue" sender:self];
}


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
    for (UITabBarItem *item in self.tabBar.items) {
        item.imageInsets = UIEdgeInsetsMake(6, 0, -6, 0);
    }
    
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
        [self.notificationBadge autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.tabBar withOffset:-12.0f];
    }
    
    if (!self.centerTabOverlay) {
        self.centerTabOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.tabBar.bounds.size.width/5.0f, self.tabBar.bounds.size.height)];
        self.centerTabOverlay.backgroundColor = [UIColor clearColor];
        
        UIView *buttonBackground = [[UIView alloc] initWithFrame:CGRectMake(10.0f, 5.0f, self.tabBar.bounds.size.width/5.0f - 20.0f, self.tabBar.bounds.size.height - 10.0f)];
        buttonBackground.backgroundColor = DW_BLUE_COLOR;
        buttonBackground.clipsToBounds = YES;
        buttonBackground.layer.cornerRadius = 4.0f;
        [self.centerTabOverlay addSubview:buttonBackground];
        [buttonBackground autoSetDimensionsToSize:CGSizeMake(self.tabBar.bounds.size.width/5.0f - 20.0f, self.tabBar.bounds.size.height - 10.0f)];
        [buttonBackground autoCenterInSuperview];
        
        UIButton *composeButton = [[UIButton alloc] initWithFrame:self.centerTabOverlay.bounds];
        composeButton.backgroundColor = [UIColor clearColor];
        [composeButton setImage:[[UIImage imageNamed:@"ComposeIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [composeButton addTarget:self action:@selector(composeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        composeButton.tintColor = self.tabBar.barTintColor;
        [self.centerTabOverlay addSubview:composeButton];
        [composeButton autoPinEdgesToSuperviewEdges];
        
        [self.tabBar addSubview:self.centerTabOverlay];
        [self.centerTabOverlay autoSetDimensionsToSize:CGSizeMake(self.tabBar.bounds.size.width/5.0f, self.tabBar.bounds.size.height)];
        [self.centerTabOverlay autoAlignAxis:ALAxisVertical toSameAxisOfView:self.tabBar];
        [self.centerTabOverlay autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.tabBar];
    }
}

@end
