//
//  DWAccessibilityAction.m
//  DireFloof
//
//  Created by John Gabelmann on 4/15/18.
//  Copyright © 2018 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <twitter_text/TwitterText.h>
#import "DWAccessibilityAction.h"
#import "MSStatus.h"

@implementation DWAccessibilityAction

#pragma mark - Class Actions

+ (NSArray *)accessibilityActionsForStatus:(MSStatus *)status atIndexPath:(NSIndexPath *)indexPath withTarget:(id)target andSelector:(SEL)selector
{
    NSMutableArray *actions = [NSMutableArray new];
    
    NSString *content = status.reblog ? status.reblog.content : status.content;
    
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray<NSTextCheckingResult *> *URLs = [detector matchesInString:status.content options:0 range:NSMakeRange(0, content.length)];
    NSArray *mentions = [TwitterText mentionedScreenNamesInText:content];
    NSArray *hashtags = [TwitterText hashtagsInText:content checkingURLOverlap:YES];
    
    for (NSTextCheckingResult *result in URLs) {
        DWAccessibilityAction *openURLAction = [[DWAccessibilityAction alloc] initWithName:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Open link", @"Open link"), result.URL.absoluteString] target:target selector:selector];
        openURLAction.actionType = DWAccessibilityActionTypeOpenUrl;
        openURLAction.url = result.URL;
        [actions addObject:openURLAction];
    }
    
    for (TwitterTextEntity *entity in mentions) {
        NSString *user = [content substringWithRange:entity.range];
        DWAccessibilityAction *openUserAction = [[DWAccessibilityAction alloc] initWithName:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"View Profile", @"View Profile"), user] target:target selector:selector];
        openUserAction.actionType = DWAccessibilityActionTypeOpenUser;
        openUserAction.user = user;
        [actions addObject:openUserAction];
    }
    
    for (TwitterTextEntity *entity in hashtags) {
        NSString *hashtag = [content substringWithRange:entity.range];
        DWAccessibilityAction *openHashtagAction = [[DWAccessibilityAction alloc] initWithName:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"View Hashtag", @"View Hashtag"), hashtag] target:target selector:selector];
        openHashtagAction.actionType = DWAccessibilityActionTypeOpenHashtag;
        openHashtagAction.hashtag = [hashtag substringFromIndex:1];
        [actions addObject:openHashtagAction];
    }
    
    return actions;
}

@end
