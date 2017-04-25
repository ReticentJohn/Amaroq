//
//  DWAppearanceProxies.m
//  DireFloof
//
//  Created by John Gabelmann on 2/14/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>
#import "DWAppearanceProxies.h"
#import "DWConstants.h"

@implementation DWAppearanceProxies

+ (void)configureAppearanceProxies
{
    [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTextColor:DW_LINK_TINT_COLOR];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline], NSForegroundColorAttributeName: [UIColor whiteColor]}];
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor clearColor]} forState:UIControlStateNormal];
    [[UINavigationBar appearance] setTranslucent:NO];
    [[UINavigationBar appearance] setBarTintColor:DW_BAR_TINT_COLOR];
    [[UINavigationBar appearance] setTintColor:DW_LINK_TINT_COLOR];
    [[UITabBar appearance] setTintColor:[UIColor whiteColor]];
}

@end
