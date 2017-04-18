//
//  DWMediaCollectionViewCell.h
//  DireFloof
//
//  Created by John Gabelmann on 2/15/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <GPUImage/GPUImage.h>
#import <AVKit/AVKit.h>
#import <UIKit/UIKit.h>

@interface DWMediaCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView *mediaImageView;
@property (nonatomic, strong) UIImageView *playImageView;
@property (nonatomic, strong) GPUImageView *gpuVideoImageView;
@property (nonatomic, strong) GPUImageMovie *gpuVideo;

@property (nonatomic, strong) NSString *identifier;
@end
