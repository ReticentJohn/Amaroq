//
//  DWSearchTableViewCell.m
//  DireFloof
//
//  Created by John Gabelmann on 2/26/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "DWSearchTableViewCell.h"

@implementation DWSearchTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    self.usernameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.displayNameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}


- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.avatarImageView.image = nil;
    self.displayNameLabel.text = @"";
    self.usernameLabel.text = @"";
    
    self.usernameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.displayNameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
