//
//  FRHyperLabel.h
//  FRHyperLabelDemo
//
//  Created by Jinghan Wang on 23/9/15.
//  Copyright © 2015 JW. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FRHyperLabel : UILabel

@property (nonatomic) NSDictionary *linkAttributeDefault;
@property (nonatomic) NSDictionary *linkAttributeHighlight;

- (void)setLinkForRange:(NSRange)range withAttributes:(NSDictionary *)attributes andLinkHandler:(void (^)(FRHyperLabel *label, NSRange selectedRange))handler;
- (void)setLinkForRange:(NSRange)range withLinkHandler:(void(^)(FRHyperLabel *label, NSRange selectedRange))handler;

- (void)setLinkForSubstring:(NSString *)substring withAttribute:(NSDictionary *)attribute andLinkHandler:(void(^)(FRHyperLabel *label, NSString *substring))handler;
- (void)setLinkForSubstring:(NSString *)substring withLinkHandler:(void(^)(FRHyperLabel *label, NSString *substring))handler;

- (void)setLinksForSubstrings:(NSArray *)substrings withLinkHandler:(void(^)(FRHyperLabel *label, NSString *substring))handler;

- (void)clearActionDictionary;

@end
