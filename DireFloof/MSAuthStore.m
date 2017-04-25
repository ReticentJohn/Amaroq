//
//  MSAuthStore.m
//  DireFloof
//
//  Created by John Gabelmann on 2/7/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <UIKit/UIKit.h>
#import <AFOAuth2Manager/AFHTTPRequestSerializer+OAuth2.h>
#import "MSAuthStore.h"
#import "MastodonConstants.h"
#import "MSAppStore.h"
#import "MSAPIClient.h"
#import "MSUserStore.h"
#import "UIApplication+TopController.h"
#import "DWNotificationStore.h"
#import "DWConstants.h"
#import "DWLoginViewController.h"

@interface MSAuthStore () <UIWebViewDelegate>

@property (nonatomic, assign, readwrite) BOOL isLoggedIn;
@property (nonatomic, strong, readwrite) NSString *token;

@property (nonatomic, copy) void (^loginBlock)(BOOL success);

@property (nonatomic, strong) NSMutableURLRequest *loginRequest;

@property (nonatomic, strong) UIButton *cancelButton;

@end

@implementation MSAuthStore

#pragma mark - Getter/Setter Overrides

- (BOOL)isLoggedIn
{
    if (!self.credential && [[MSAppStore sharedStore] isRegistered]) {
        AFOAuthCredential *credential = [AFOAuthCredential retrieveCredentialWithIdentifier:[[MSAppStore sharedStore] base_api_url_string]];
        
        if (credential) {
            self.credential = credential;
        }
    }
    
    return self.credential != nil;
}


#pragma mark - Class Methods

+ (MSAuthStore *)sharedStore
{
    static MSAuthStore *sharedStore = nil;
    static dispatch_once_t storeToken;
    dispatch_once(&storeToken, ^{
        
        sharedStore = [[MSAuthStore alloc] init];
    });
    
    return sharedStore;
}


#pragma mark - Instance Methods

- (void)login:(void (^)(BOOL))completion
{
    if (self.credential) {
        
        [[MSUserStore sharedStore] getCurrentUserWithCompletion:^(BOOL success, MSAccount *user, NSError *error) {
            if (completion != nil) {
                completion([self isLoggedIn]);
            }
        }];
        
    }
    else
    {
        if ([[MSAppStore sharedStore] isRegistered]) {
            
            AFOAuthCredential *credential = [AFOAuthCredential retrieveCredentialWithIdentifier:[[MSAppStore sharedStore] base_api_url_string]];
            
            if (credential) {
                self.credential = credential;
                
                [[MSUserStore sharedStore] getCurrentUserWithCompletion:^(BOOL success, MSAccount *user, NSError *error) {
                    if (completion != nil) {
                        completion([self isLoggedIn]);
                    }
                }];
            }
            else
            {
                self.loginBlock = completion;
                [self performWebviewLogin];
            }

        }
        else
        {
            [[MSAppStore sharedStore] registerApp:^(BOOL success) {
                // If this fails we're SOL, for now I'm going to loop this chitz
                if (success) {
                    self.loginBlock = completion;
                    [self performWebviewLogin];
                }
                else
                {
                    if (completion != nil) {
                        completion(NO);
                    }
                }
            }];
        }

    }
}


- (void)registerForRemoteNotificationsWithToken:(NSString *)token
{
    if (!token || ![self isLoggedIn]) {
        return;
    }
    
    NSDictionary *params = @{@"instance_url": [[MSAppStore sharedStore] base_url_string],
                             @"access_token": self.credential.accessToken,
                             @"device_token": token};
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/plain"];

    [manager POST:[NSString stringWithFormat:@"%@register", MS_APNS_URL_STRING] parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //NSLog(@"Registered for APNS!");
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:MS_LAST_APNS_REFRESH_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        //NSLog(@"Failed to register for APNS!");
    }];
}


- (void)unregisterForRemoteNotifications
{
    NSDictionary *params = @{@"instance_url": [[MSAppStore sharedStore] base_url_string],
                             @"access_token": self.credential.accessToken};
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/plain"];
    
    [manager POST:[NSString stringWithFormat:@"%@unregister", MS_APNS_URL_STRING] parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        //NSLog(@"unRegistered for APNS!");
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        //NSLog(@"Failed to unregister for APNS!");
    }];
}


#pragma mark - UIWebviewDelegate Methods


- (void)webViewDidStartLoad:(UIWebView *)webView
{
    
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ((![request.mainDocumentURL.absoluteString containsString:@"/auth"] && ![request.mainDocumentURL.absoluteString containsString:@"/settings"]) || ([request.mainDocumentURL.absoluteString isEqualToString:[[MSAppStore sharedStore] base_url_string]] && [self isLoggedIn]))
    {
        webView.alpha = 0.0f;
        webView.hidden = YES;
        self.cancelButton.alpha = 0.0f;
        self.cancelButton.hidden = YES;
    }
    
    return YES;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *html = [webView stringByEvaluatingJavaScriptFromString:
                      @"document.body.innerHTML"];
    
    //NSLog(@"%@", webView.request.mainDocumentURL.absoluteString);
    
    if ([html containsString:@"access_token"]) {
        NSArray *components = [html componentsSeparatedByString:@"\""];
        
        // lol so stable yo
        NSString *access_token = [components objectAtIndex:[components indexOfObject:@"access_token"]+2];
        
        self.credential = [[AFOAuthCredential alloc] initWithOAuthToken:access_token tokenType:@"Bearer"];
        [self.credential setExpiration:[NSDate distantFuture]];
        [AFOAuthCredential storeCredential:self.credential withIdentifier:[[MSAppStore sharedStore] base_api_url_string]];
        
        if ([[[[UIApplication sharedApplication] topController] view].subviews containsObject:webView]) {
            webView.delegate = nil;
            [webView removeFromSuperview];
            [self.cancelButton removeFromSuperview];
        }
        
        [[MSUserStore sharedStore] getCurrentUserWithCompletion:^(BOOL success, MSAccount *user, NSError *error) {
            if (self.loginBlock != nil) {
                self.loginBlock([self isLoggedIn]);
            }
        }];
        
    }
    else if ([webView.request.mainDocumentURL.absoluteString isEqualToString:[[MSAppStore sharedStore] base_url_string]] && [self isLoggedIn])
    {
        // we have gone too far
        if ([[[[UIApplication sharedApplication] topController] view].subviews containsObject:webView]) {
            webView.delegate = nil;
            [webView removeFromSuperview];
            [self.cancelButton removeFromSuperview];
        }
    }
    else if (([webView.request.mainDocumentURL.absoluteString containsString:@"/about"] || [webView.request.mainDocumentURL.absoluteString containsString:@"sign_in"]) && [self isLoggedIn] && !self.loginRequest)
    {
        // YOU FOOL YOU'VE LOGGED OUT
        if ([[[[UIApplication sharedApplication] topController] view].subviews containsObject:webView]) {
            webView.delegate = nil;
            [webView removeFromSuperview];
            [self.cancelButton removeFromSuperview];
        }
        
        [[MSAuthStore sharedStore] logout];
    }
    else if (![webView.request.mainDocumentURL.absoluteString containsString:@"/auth"] && ![webView.request.mainDocumentURL.absoluteString containsString:@"/settings"])
    {
        [webView loadRequest:self.loginRequest];
    }
    else
    {
        webView.hidden = NO;
        self.cancelButton.hidden = NO;
        [UIView animateWithDuration:0.2f animations:^{
            webView.alpha = 1.0f;
            self.cancelButton.alpha = 1.0f;
        }];
    }
}


- (void)requestEditProfile
{
    [self performOtherWebviewRequestWithUrl:[NSString stringWithFormat:@"%@settings/profile", [[MSAppStore sharedStore] base_url_string]]];
}


- (void)requestPreferences
{
    [self performOtherWebviewRequestWithUrl:[NSString stringWithFormat:@"%@settings/preferences", [[MSAppStore sharedStore] base_url_string]]];
}


- (void)logout
{
    [[DWNotificationStore sharedStore] stopNotificationRefresh];

    [[NSURLSession sharedSession] resetWithCompletionHandler:^{
        
        self.credential = nil;
        [AFOAuthCredential deleteCredentialWithIdentifier:[[MSAppStore sharedStore] base_api_url_string]];
        [[[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] requestSerializer] setAuthorizationHeaderFieldWithCredential:nil];
        
        for (NSDictionary *instance in [[MSAppStore sharedStore] availableInstances]) {
            [AFOAuthCredential deleteCredentialWithIdentifier:[instance objectForKey:MS_BASE_API_URL_STRING_KEY]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[[UIApplication sharedApplication] keyWindow] rootViewController] dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}


- (void)switchToInstance:(NSString *)instance withCompletion:(void (^)(BOOL))completion
{
    [[DWNotificationStore sharedStore] stopNotificationRefresh];
    
    self.credential = nil;
    [[[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] requestSerializer] setAuthorizationHeaderFieldWithCredential:nil];

    [[MSAppStore sharedStore] setMastodonInstance:instance];
    
    if ([self isLoggedIn]) {
        
        [[MSUserStore sharedStore] getCurrentUserWithCompletion:nil];
        
        [[DWNotificationStore sharedStore] registerForNotifications];
        
        if (completion != nil) {
            completion(YES);
        }
    }
    else
    {
        [self login:^(BOOL success) {
            
            if (success) {
                [[DWNotificationStore sharedStore] registerForNotifications];
            }
            
            if (completion != nil) {
                completion(success);
            }
        }];
    }
}


- (void)requestAddInstanceAccount
{
    DWLoginViewController *loginController = [[UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateInitialViewController];
    loginController.addAccount = YES;
    loginController.modalPresentationStyle = UIModalPresentationOverFullScreen;
    loginController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    [[DWNotificationStore sharedStore] stopNotificationRefresh];
    [[[UIApplication sharedApplication] topController] presentViewController:loginController animated:YES completion:nil];
}


#pragma mark - Private Methods

- (void)performWebviewLogin
{
    NSString *body = [NSString stringWithFormat:@"client_id=%@&client_secret=%@&grant_type=password&scope=read write follow", [[MSAppStore sharedStore] client_id], [[MSAppStore sharedStore] client_secret]];
    
    self.loginRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@oauth/token", [[MSAppStore sharedStore] base_url_string]]]];
    [self.loginRequest setHTTPMethod:@"POST"];
    [self.loginRequest setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    if (!self.cancelButton) {
        self.cancelButton = [[UIButton alloc] initWithFrame:CGRectMake([UIApplication sharedApplication].keyWindow.bounds.size.width - 79, 0, 79, 79)];
        self.cancelButton.tintColor = [UIColor whiteColor];
        [self.cancelButton setImage:[UIImage imageNamed:@"CloseIcon"] forState:UIControlStateNormal];
        [self.cancelButton addTarget:self action:@selector(cancelWebviewLogin) forControlEvents:UIControlEventTouchUpInside];
    }
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.bounds];
    webView.delegate = self;
    
    webView.alpha = 0.0f;
    self.cancelButton.alpha = 0.0f;
    webView.tag = 1337;
    webView.scrollView.bounces = NO;
    [[[[UIApplication sharedApplication] topController] view] addSubview:webView];
    [[[[UIApplication sharedApplication] topController] view] bringSubviewToFront:webView];
    [[[[UIApplication sharedApplication] topController] view] addSubview:self.cancelButton];
    [[[[UIApplication sharedApplication] topController] view] bringSubviewToFront:self.cancelButton];
    
    [webView loadRequest:self.loginRequest];
}


- (void)cancelWebviewLogin
{
    UIWebView *webView = [[[[UIApplication sharedApplication] topController] view] viewWithTag:1337];
    
    if (webView) {
        webView.delegate = nil;
        [webView removeFromSuperview];
    }
    
    [self.cancelButton removeFromSuperview];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DW_DID_CANCEL_LOGIN_NOTIFICATION object:nil];
}


- (void)performOtherWebviewRequestWithUrl:(NSString *)url
{
    UIWebView *webView = [[UIWebView alloc] initWithFrame:[UIApplication sharedApplication].keyWindow.bounds];
    webView.delegate = self;
    
    webView.alpha = 0.0f;
    webView.tag = 1337;
    webView.scrollView.bounces = NO;
    webView.opaque = NO;
    webView.backgroundColor = DW_BACKGROUND_COLOR;
    [[[[UIApplication sharedApplication] topController] view] addSubview:webView];
    [[[[UIApplication sharedApplication] topController] view] bringSubviewToFront:webView];
    
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    
    [UIView animateWithDuration:0.3f animations:^{
        webView.alpha = 1.0f;
    }];
}


@end
