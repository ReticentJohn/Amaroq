//
//  UIView+Supercell.m
//  DireFloof
//
//  Created by John Gabelmann on 2/27/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "UIView+Supercell.h"

@implementation UIView (Supercell)

- (UITableViewCell *)supercell
{
    if ([self isKindOfClass:[UITableViewCell class]]) {
        return (UITableViewCell *)self;
    }
    
    UIView *superview = self.superview;
    
    while (![superview isKindOfClass:[UITableViewCell class]] && superview) {
        
        superview = superview.superview;
    }
    
    return (UITableViewCell *)superview;
}

@end
