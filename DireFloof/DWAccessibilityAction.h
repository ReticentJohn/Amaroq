//
//  DWAccessibilityAction.h
//  DireFloof
//
//  Created by John Gabelmann on 4/15/18.
//  Copyright © 2018 Keyboard Floofs. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DWConstants.h"

@class MSStatus;

@interface DWAccessibilityAction : UIAccessibilityCustomAction

#pragma mark - Properties

@property (nonatomic, assign) DWAccessibilityActionType actionType;
@property (nonatomic, strong) NSString *user;
@property (nonatomic, strong) NSString *hashtag;
@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSIndexPath *indexPath;

#pragma mark - Class Actions

+ (NSArray *)accessibilityActionsForStatus:(MSStatus *)status atIndexPath:(NSIndexPath *)indexPath withTarget:(id)target andSelector:(SEL)selector;

@end
