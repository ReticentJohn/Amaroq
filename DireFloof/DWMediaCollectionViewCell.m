//
//  DWMediaCollectionViewCell.m
//  DireFloof
//
//  Created by John Gabelmann on 2/15/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <PureLayout/PureLayout.h>
#import "DWMediaCollectionViewCell.h"

@implementation DWMediaCollectionViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    if (!self.playImageView) {
        self.playImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PlayIcon"]];
        self.playImageView.tintColor = [UIColor whiteColor];
        self.playImageView.contentMode = UIViewContentModeScaleAspectFit;
        self.playImageView.hidden = YES;
        [self.contentView addSubview:self.playImageView];
        [self.playImageView autoCenterInSuperview];
        [self.playImageView autoSetDimensionsToSize:CGSizeMake(50, 50)];
    }
}


- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.mediaImageView.image = nil;
    self.playImageView.hidden = YES;
    
    if (self.gpuVideoImageView) {
        [self.gpuVideo removeTarget:self.gpuVideoImageView];
        [self.gpuVideo cancelProcessing];
        
        self.gpuVideoImageView.backgroundColor = [UIColor clearColor];
        [self.gpuVideoImageView setBackgroundColorRed:0 green:0 blue:0 alpha:0];
        self.gpuVideoImageView.hidden = YES;
        
        [self.gpuVideoImageView removeFromSuperview];
    
        [[NSNotificationCenter defaultCenter] removeObserver:self.gpuVideo];
        
        self.gpuVideoImageView = nil;
        self.gpuVideo = nil;
    }
}

@end
