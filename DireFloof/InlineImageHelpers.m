//
//  NSMutableAttributedString+InlineImage.m
//  DireFloof
//
//  Created by John Gabelmann on 11/16/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "InlineImageHelpers.h"

@implementation NSMutableAttributedString (InlineImage)

- (void)replaceCharactersInRange:(NSRange)range withInlineImage:(UIImage *)inlineImage scale:(CGFloat)inlineImageScale {
    
    if (floorf(inlineImageScale) == 0)
        inlineImageScale = 1.0f;
    
    // Create resized, tinted image matching font size and (text) color
    UIImage *imageMatchingFont = [inlineImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    {
        // Font size
        NSDictionary *attributesForRange = [self attributesAtIndex:range.location effectiveRange:nil];
        UIFont *fontForRange = [attributesForRange valueForKey:NSFontAttributeName];
        
        // We want just a bit smaller than the literal cap height because the images will actually kiss the overall line height just enough to trip word wrapping; the intrinsic content size of the label does not know how to account for this
        CGFloat adjustedCapHeight = fontForRange.capHeight - 1.0f;
        CGSize imageSizeMatchingFontSize = CGSizeMake(inlineImage.size.width * (adjustedCapHeight / inlineImage.size.height), adjustedCapHeight);
        
        // Some scaling for prettiness
        CGFloat defaultScale = 1.4f;
        imageSizeMatchingFontSize = CGSizeMake(imageSizeMatchingFontSize.width * defaultScale,     imageSizeMatchingFontSize.height * defaultScale);
        imageSizeMatchingFontSize = CGSizeMake(imageSizeMatchingFontSize.width * inlineImageScale, imageSizeMatchingFontSize.height * inlineImageScale);
        imageSizeMatchingFontSize = CGSizeMake(ceilf(imageSizeMatchingFontSize.width), ceilf(imageSizeMatchingFontSize.height));
        
        // Text color
        UIColor *textColorForRange = [attributesForRange valueForKey:NSForegroundColorAttributeName];
        
        // Make the matching image
        UIGraphicsBeginImageContextWithOptions(imageSizeMatchingFontSize, NO, 0.0f);
        [textColorForRange set];
        [inlineImage drawInRect:CGRectMake(0 , 0, imageSizeMatchingFontSize.width, imageSizeMatchingFontSize.height)];
        imageMatchingFont = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    // Text attachment with image
    NSTextAttachment *textAttachment = [NSTextAttachment new];
    textAttachment.image = imageMatchingFont;
    NSAttributedString *imageString = [NSAttributedString attributedStringWithAttachment:textAttachment];
    
    [self replaceCharactersInRange:range withAttributedString:imageString];
}

@end


@implementation NSAttributedString (InlineImages)

- (NSAttributedString *)attributedStringByReplacingOccurancesOfString:(NSString *)string withInlineImage:(UIImage *)inlineImage scale:(CGFloat)inlineImageScale {
    
    NSMutableAttributedString *attributedStringWithImages = [self mutableCopy];
    
    [attributedStringWithImages.string enumerateOccurancesOfString:string usingBlock:^(NSRange substringRange, BOOL *stop) {
        [attributedStringWithImages replaceCharactersInRange:substringRange withInlineImage:inlineImage scale:inlineImageScale];
        
    }];
    
    return [attributedStringWithImages copy];
}

@end


@implementation NSString (EnumerateOccurancesOfString)

- (void)enumerateOccurancesOfString:(NSString *)string usingBlock:(void (^)(NSRange range, BOOL * _Nonnull stop))block {
    
    NSParameterAssert(block);
    
    NSRange range = [self localizedStandardRangeOfString:string];
    
    if (range.location == NSNotFound) return;
    
    
    // Iterate all occurances of 'string'
    while (range.location != NSNotFound)
    {
        BOOL stop = NO;
        
        block(range, &stop);
        
        if (stop) {
            break;
        }
        
        // Continue the iteration
        NSRange nextRange = NSMakeRange(range.location + 1, self.length - range.location - 1);
        range = [self rangeOfString:string options:(NSStringCompareOptions)0 range:nextRange locale:[NSLocale currentLocale]]; // Will this sometimes conflict with the initial range obtained with -localizedStandardRangeOfString:?
    }
}

@end
