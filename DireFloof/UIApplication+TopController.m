//
//  UIApplication+TopController.m
//  DireFloof
//
//  Created by John Gabelmann on 2/26/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "UIApplication+TopController.h"

@implementation UIApplication (TopController)

- (UIViewController *)topController
{
    UIViewController *topController = self.keyWindow.rootViewController;
    
    if (!topController) {
        return nil;
    }
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

@end
