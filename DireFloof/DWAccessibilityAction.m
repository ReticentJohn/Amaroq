//
//  DWAccessibilityAction.m
//  DireFloof
//
//  Created by John Gabelmann on 4/15/18.
//  Copyright © 2018 Keyboard Floofs. All rights reserved.
//

#import <twitter_text/TwitterText.h>
#import "DWAccessibilityAction.h"
#import "MSStatus.h"

@implementation DWAccessibilityAction

#pragma mark - Class Actions

+ (NSArray *)accessibilityActionsForStatus:(MSStatus *)status atIndexPath:(NSIndexPath *)indexPath withTarget:(id)target andSelector:(SEL)selector
{
    NSMutableArray *actions = [NSMutableArray new];
    
    /*DWAccessibilityAction *openThreadAction = [[DWAccessibilityAction alloc] initWithName:NSLocalizedString(@"Open Thread", @"Open Thread") target:target selector:selector];
    openThreadAction.actionType = DWAccessibilityActionTypeOpenThread;
    openThreadAction.indexPath = indexPath;
    [actions addObject:openThreadAction];*/
    
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray<NSTextCheckingResult *> *URLs = [detector matchesInString:status.content options:0 range:NSMakeRange(0, status.content.length)];
    NSArray *mentions = [TwitterText mentionedScreenNamesInText:status.content];
    NSArray *hashtags = [TwitterText hashtagsInText:status.content checkingURLOverlap:YES];
    
    for (NSTextCheckingResult *result in URLs) {
        DWAccessibilityAction *openURLAction = [[DWAccessibilityAction alloc] initWithName:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Open link", @"Open link"), result.URL.absoluteString] target:target selector:selector];
        openURLAction.actionType = DWAccessibilityActionTypeOpenUrl;
        openURLAction.url = result.URL;
        [actions addObject:openURLAction];
    }
    
    for (TwitterTextEntity *entity in mentions) {
        NSString *user = [status.content substringWithRange:entity.range];
        DWAccessibilityAction *openUserAction = [[DWAccessibilityAction alloc] initWithName:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"View Profile", @"View Profile"), user] target:target selector:selector];
        openUserAction.actionType = DWAccessibilityActionTypeOpenUser;
        openUserAction.user = user;
        [actions addObject:openUserAction];
    }
    
    for (TwitterTextEntity *entity in hashtags) {
        NSString *hashtag = [status.content substringWithRange:entity.range];
        DWAccessibilityAction *openHashtagAction = [[DWAccessibilityAction alloc] initWithName:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"View Hashtag", @"View Hashtag"), hashtag] target:target selector:selector];
        openHashtagAction.actionType = DWAccessibilityActionTypeOpenHashtag;
        openHashtagAction.hashtag = [hashtag substringFromIndex:1];
        [actions addObject:openHashtagAction];
    }
    
    return actions;
}

@end
