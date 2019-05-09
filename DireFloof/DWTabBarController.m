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
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "DWTabBarController.h"
#import "Mastodon.h"
#import "DWNotificationStore.h"
#import "DWConstants.h"
#import "DWTimelineViewController.h"
#import "DWNotificationsViewController.h"
#import "DWAppearanceProxies.h"
#import "DWSettingStore.h"
#import "UIApplication+TopController.h"

typedef NS_ENUM(NSUInteger, DWTabItem) {
    DWTabItemHome = 0,
    DWTabItemPublic,
    DWTabItemBlank,
    DWTabItemNotifications,
    DWTabItemMenu,
};

@interface DWTabBarController ()
@property (nonatomic, strong) UIView *notificationBadge;
@property (nonatomic, strong) UIView *centerTabOverlay;
@property (nonatomic, strong) UIImageView *avatarImageView;

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
    
    
    self.previousSelectedIndex = 0;
    
    [[DWNotificationStore sharedStore] registerForNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureViews) name:DW_DID_SWITCH_INSTANCES_NOTIFICATION object:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Refresh the current user
    [self configureViews];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DW_WILL_PURGE_CACHE_NOTIFICATION object:nil];
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


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    if (index == DWTabItemBlank) {
        [self setSelectedIndex:self.previousSelectedIndex];
        [self setSelectedViewController:[self.viewControllers objectAtIndex:self.previousSelectedIndex]];
        [self composeButtonPressed];
        return;
    }

    if (self.previousSelectedIndex == index && [[[self.viewControllers objectAtIndex:index] viewControllers] count] == 1) {
        
        if (index == DWTabItemHome || index == DWTabItemPublic) {
            
            DWTimelineViewController *currentController = [[[self.viewControllers objectAtIndex:index] viewControllers] firstObject];
            [currentController scrollToTop:nil];
        }
        else if (index == DWTabItemNotifications)
        {
            DWNotificationsViewController *currentController = [[[self.viewControllers objectAtIndex:index] viewControllers] firstObject];
            [currentController scrollToTop:nil];
        }
    }
    else
    {
        self.previousSelectedIndex = index;
        [[NSNotificationCenter defaultCenter] postNotificationName:DW_WILL_PURGE_CACHE_NOTIFICATION object:nil];
        [[[[self.viewControllers objectAtIndex:index] viewControllers] firstObject] viewDidAppear:NO];
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
        
        if ([self.tabBar.items indexOfObject:item] == DWTabItemPublic) {
            [item setImage:[[DWSettingStore sharedStore] showLocalTimeline] ? [UIImage imageNamed:@"LocalIcon"] : [UIImage imageNamed:@"PublicIcon"]];
            [item setSelectedImage:[[DWSettingStore sharedStore] showLocalTimeline] ? [UIImage imageNamed:@"LocalIcon"] : [UIImage imageNamed:@"PublicIcon"]];

        }
    }
    
    // Collect the window and determine the true width when we're in portrait mode
    CGRect windowBounds = [UIApplication sharedApplication].keyWindow.bounds;
    CGFloat width = MIN(windowBounds.size.height, windowBounds.size.width);
    
    if (!self.notificationBadge) {
        self.notificationBadge = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        self.notificationBadge.clipsToBounds = YES;
        self.notificationBadge.layer.cornerRadius = 5.0f;
        self.notificationBadge.backgroundColor = DW_BLUE_COLOR;
        self.notificationBadge.hidden = YES;
        self.notificationBadge.userInteractionEnabled = NO;
        
        [self.tabBar addSubview:self.notificationBadge];
        
        [self.notificationBadge autoSetDimensionsToSize:CGSizeMake(10, 10)];
        UIView *notificationIconView = [DWTabBarController iconViewForTabInTabBar:self.tabBar withIndex:DWTabItemNotifications];
        [self.notificationBadge autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:notificationIconView withOffset: -4.0f];
        [self.notificationBadge autoAlignAxis:ALAxisVertical toSameAxisOfView:notificationIconView withOffset: 12.0f];
        [[DWNotificationStore sharedStore] setNotificationBadge:self.notificationBadge];
    }
    
    if (!self.centerTabOverlay) {
        self.centerTabOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width/5.0f, 49.0f)];
        self.centerTabOverlay.backgroundColor = [UIColor clearColor];
        
        UIView *buttonBackground = [[UIView alloc] initWithFrame:CGRectMake(10.0f, 5.0f, width/5.0f - 20.0f, 39.0f)];
        buttonBackground.backgroundColor = DW_BLUE_COLOR;
        buttonBackground.clipsToBounds = YES;
        buttonBackground.layer.cornerRadius = 4.0f;
        [self.centerTabOverlay addSubview:buttonBackground];
        [buttonBackground autoSetDimensionsToSize:CGSizeMake(width/5.0f - 20.0f, 39.0f)];
        [buttonBackground autoCenterInSuperview];
        
        UIButton *composeButton = [[UIButton alloc] initWithFrame:self.centerTabOverlay.bounds];
        composeButton.backgroundColor = [UIColor clearColor];
        [composeButton setImage:[[UIImage imageNamed:@"ComposeIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [composeButton addTarget:self action:@selector(composeButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        composeButton.tintColor = self.tabBar.barTintColor;
        [self.centerTabOverlay addSubview:composeButton];
        [composeButton autoPinEdgesToSuperviewEdges];
        
        [self.tabBar addSubview:self.centerTabOverlay];
        [self.centerTabOverlay autoSetDimensionsToSize:CGSizeMake(width/5.0f, 49.0f)];
        [self.centerTabOverlay autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.tabBar];
        [self.centerTabOverlay autoAlignAxis:ALAxisVertical toSameAxisOfView:self.tabBar];
    }
    
    if (!self.avatarImageView) {
        UIView *menuOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 21.0f, 21.0f)];
        menuOverlay.clipsToBounds = YES;
        menuOverlay.layer.cornerRadius = 4.0f;
        menuOverlay.backgroundColor = self.tabBar.barTintColor;
        menuOverlay.userInteractionEnabled = NO;
        menuOverlay.layer.borderWidth = 2.0f;
        menuOverlay.layer.borderColor = self.tabBar.barTintColor.CGColor;
        
        self.avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 21.0f, 21.0f)];
        self.avatarImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.avatarImageView.clipsToBounds = YES;
        self.avatarImageView.backgroundColor = [UIColor clearColor];
        
        [menuOverlay addSubview:self.avatarImageView];
        [self.avatarImageView autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(2, 2, 2, 2)];

        [self.tabBar addSubview:menuOverlay];
        [menuOverlay autoSetDimensionsToSize:CGSizeMake(21.0f, 21.0f)];
        UIView *menuIconView = [DWTabBarController iconViewForTabInTabBar:self.tabBar withIndex:DWTabItemMenu];
        [self.avatarImageView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:menuIconView withOffset: -4.0f];
        [self.avatarImageView autoAlignAxis:ALAxisVertical toSameAxisOfView:menuIconView withOffset: 8.0f];
    }
    
    __weak UIImageView *__avatarImageView = self.avatarImageView;
    __weak DWTabBarController *__self = self;
    [[MSUserStore sharedStore] getCurrentUserWithCompletion:^(BOOL success, MSAccount *user, NSError *error) {
        if (success) {
            [self.avatarImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[[DWSettingStore sharedStore] disableGifPlayback] ? user.avatar_static : user.avatar]] placeholderImage:nil success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
                
                if (image) {
                    __avatarImageView.image = image;
                    if ([[DWSettingStore sharedStore] disableGifPlayback]) {
                        [__avatarImageView stopAnimating];
                    }
                }
                
            } failure:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, NSError * _Nonnull error) {
                [__self configureViews];
            }];
        }
        else
        {
            [self configureViews];
        }
        
    }];
}

+ (UIView *)iconViewForTabInTabBar:(UITabBar*)tabBar withIndex:(NSUInteger)index
{
    NSMutableArray *tabBarItems = [NSMutableArray arrayWithCapacity:[tabBar.items count]];
    for (UIView *view in tabBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UITabBarButton")] && [view respondsToSelector:@selector(frame)]) {
            // check for the selector -frame to prevent crashes in the very unlikely case that in the future
            // objects thar don't implement -frame can be subViews of an UIView
            [tabBarItems addObject:view];
        }
    }
    if ([tabBarItems count] == 0) {
        // no tabBarItems means either no UITabBarButtons were in the subView, or none responded to -frame
        // return CGRectZero to indicate that we couldn't figure out the frame
        return Nil;
    }
    
    // sort by origin.x of the frame because the items are not necessarily in the correct order
    [tabBarItems sortUsingComparator:^NSComparisonResult(UIView *view1, UIView *view2) {
        if (view1.frame.origin.x < view2.frame.origin.x) {
            return NSOrderedAscending;
        }
        if (view1.frame.origin.x > view2.frame.origin.x) {
            return NSOrderedDescending;
        }
        NSAssert(NO, @"%@ and %@ share the same origin.x. This should never happen and indicates a substantial change in the framework that renders this method useless.", view1, view2);
        return NSOrderedSame;
    }];
    
    UIView *view;
    if (index < [tabBarItems count]) {
        // viewController is in a regular tab
        UIView *tabView = tabBarItems[index];
        if ([tabView respondsToSelector:@selector(frame)]) {
            view = tabView;
        }
    }
    else {
        // our target viewController is inside the "more" tab
        UIView *tabView = [tabBarItems lastObject];
        if ([tabView respondsToSelector:@selector(frame)]) {
            view = tabView;
        }
    }
    return view.subviews[0];
}

@end
