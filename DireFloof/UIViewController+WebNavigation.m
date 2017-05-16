//
//  UIViewController+WebNavigation.m
//  DireFloof
//
//  Created by Tim Johnsen on 5/12/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//

#import "UIViewController+WebNavigation.h"
#import <SafariServices/SafariServices.h>

@implementation UIViewController (WebNavigation)

- (void)openWebURL:(NSURL *const)url
{
    NSString *const scheme = url.scheme.lowercaseString;
    const BOOL isWebLink = [scheme isEqualToString:@"http"] || [scheme isEqualToString:@"https"];
    if (isWebLink && [SFSafariViewController class]) {
        // iOS 9 or later
        // SFSafariViewController crashes for non-HTTP(s) links, which is why we validate above.
        SFSafariViewController *safariViewController = [[SFSafariViewController alloc] initWithURL:url];
        [self presentViewController:safariViewController animated:YES completion:nil];
    } else if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_9_x_Max) {
        [[UIApplication sharedApplication] openURL:url];
    } else {
        // iOS 10 or later
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
}

@end
