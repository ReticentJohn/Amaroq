//
//  InlineImageHelpers.h
//  DireFloof
//
//  Created by John Gabelmann on 11/16/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSMutableAttributedString (InlineImage)

- (void)replaceCharactersInRange:(NSRange)range withInlineImage:(UIImage *)inlineImage scale:(CGFloat)inlineImageScale;

@end

@interface NSAttributedString (InlineImages)

- (NSAttributedString *)attributedStringByReplacingOccurancesOfString:(NSString *)string withInlineImage:(UIImage *)inlineImage scale:(CGFloat)inlineImageScale;

@end

@interface NSString (EnumerateOccurancesOfString)

- (void)enumerateOccurancesOfString:(NSString *)string usingBlock:(void (^)(NSRange substringRange, BOOL *stop))block;

@end
