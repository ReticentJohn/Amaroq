//
//  DWIntrinsicCollectionView.m
//  DireFloof
//
//  Created by John Gabelmann on 2/15/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "DWIntrinsicCollectionView.h"

@implementation DWIntrinsicCollectionView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (CGSize)intrinsicContentSize
{
    return self.collectionViewLayout.collectionViewContentSize;
}

@end
