//
//  UIViewController+WebNavigation.h
//  DireFloof
//
//  Created by Tim Johnsen on 5/12/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (WebNavigation)

- (void)openWebURL:(NSURL *const)url;

@end

NS_ASSUME_NONNULL_END
