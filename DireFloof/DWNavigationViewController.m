//
//  DWNavigationViewController.m
//  DireFloof
//
//  Created by John Gabelmann on 3/10/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "DWNavigationViewController.h"


@interface InteractivePopGestureDelegate : NSObject <UIGestureRecognizerDelegate>

@property (nonatomic, weak) UINavigationController *navigationController;
@property (nonatomic, weak) id<UIGestureRecognizerDelegate> originalDelegate;

@end

@implementation InteractivePopGestureDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if (self.navigationController.navigationBarHidden && self.navigationController.viewControllers.count > 1) {
        return YES;
    } else {
        return [self.originalDelegate gestureRecognizer:gestureRecognizer shouldReceiveTouch:touch];
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    if (aSelector == @selector(gestureRecognizer:shouldReceiveTouch:)) {
        return YES;
    } else {
        return [self.originalDelegate respondsToSelector:aSelector];
    }
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return self.originalDelegate;
}

@end


@interface DWNavigationViewController ()

@property (nonatomic) InteractivePopGestureDelegate *interactivePopGestureDelegate;

@end


@implementation DWNavigationViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.interactivePopGestureDelegate = [InteractivePopGestureDelegate new];
    self.interactivePopGestureDelegate.navigationController = self;
    self.interactivePopGestureDelegate.originalDelegate = self.interactivePopGestureRecognizer.delegate;
    self.interactivePopGestureRecognizer.delegate = self.interactivePopGestureDelegate;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


- (BOOL)shouldAutorotate
{
    return NO;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */


- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    if (self.presentedViewController || ![self.view viewWithTag:1337])
    {
        [super dismissViewControllerAnimated:flag completion:completion];
    }
}

@end
