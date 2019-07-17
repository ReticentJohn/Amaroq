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
#import <OAuth2/OAuthRequestController.h>
#import "MSAuthStore.h"
#import "MastodonConstants.h"
#import "MSAppStore.h"
#import "MSAPIClient.h"
#import "MSUserStore.h"
#import "UIApplication+TopController.h"
#import "UIViewController+WebNavigation.h"
#import "DWNotificationStore.h"
#import "DWConstants.h"
#import "DWLoginViewController.h"
#import "DWSettingStore.h"

@interface MSAuthStore () <OAuthRequestControllerDelegate>

@property (nonatomic, assign, readwrite) BOOL isLoggedIn;
@property (nonatomic, strong, readwrite) NSString *token;

@property (nonatomic, copy) void (^loginBlock)(BOOL success);

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


- (void)unregisterForRemoteNotifications
{
    if (![[MSAppStore sharedStore] base_url_string] || !self.credential.accessToken) {
        return;
    }
    
    [[MSNotificationStore sharedStore] unsubscribePushNotifications];
}


- (void)requestEditProfile
{
    [[[UIApplication sharedApplication] topController] openWebURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@settings/profile", [[MSAppStore sharedStore] base_url_string]]]];
}


- (void)requestPreferences
{
    [[[UIApplication sharedApplication] topController] openWebURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@settings/preferences", [[MSAppStore sharedStore] base_url_string]]]];
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
            [[MSAppStore sharedStore] removeMastodonInstance:[instance objectForKey:MS_INSTANCE_KEY]];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[[UIApplication sharedApplication] keyWindow] rootViewController] dismissViewControllerAnimated:YES completion:nil];
        });
    }];
}


- (void)logoutOfInstance:(NSString *)instance
{
    NSDictionary *instanceToRemove = [[[[MSAppStore sharedStore] availableInstances] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"MS_INSTANCE_KEY LIKE[cd] %@", instance]] firstObject];
    
    if (instanceToRemove) {
        
        NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
        for (NSHTTPCookie *cookie in [storage cookies]) {
            
            if ([cookie.domain isEqualToString:instance]) {
                [storage deleteCookie:cookie];
            }
        }
        
        [AFOAuthCredential deleteCredentialWithIdentifier:[instanceToRemove objectForKey:MS_BASE_API_URL_STRING_KEY]];
        [[[MSAPIClient sharedClientWithBaseAPI:[instanceToRemove objectForKey:MS_BASE_API_URL_STRING_KEY]] requestSerializer] setAuthorizationHeaderFieldWithCredential:nil];
        [[MSAppStore sharedStore] removeMastodonInstance:instance];
    }
}


- (void)switchToInstance:(NSString *)instance withCompletion:(void (^)(BOOL))completion
{
    [[DWNotificationStore sharedStore] stopNotificationRefresh];
    
    self.credential = nil;
    [[[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] requestSerializer] setAuthorizationHeaderFieldWithCredential:nil];

    [[MSAppStore sharedStore] setMastodonInstance:instance];
    
    if ([self isLoggedIn]) {
        
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


#pragma mark - OAuthRequestController Delegate Methods

- (void)didAuthorized:(NSDictionary *)dictResponse {
    
    self.credential = [[AFOAuthCredential alloc] initWithOAuthToken:[dictResponse objectForKey:kOAuth_AccessToken] tokenType:@"Bearer"];
    [self.credential setExpiration:[NSDate distantFuture]];
    [AFOAuthCredential storeCredential:self.credential withIdentifier:[[MSAppStore sharedStore] base_api_url_string]];
    
    if (self.loginBlock != nil) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.loginBlock([self isLoggedIn]);
        });
    }
}


#pragma mark - Private Methods

- (void)performWebviewLogin
{
    NSMutableDictionary *dictService = [NSMutableDictionary dictionary];
    [dictService setObject:[NSString stringWithFormat:@"%@oauth/authorize", [[MSAppStore sharedStore] base_url_string]] forKey:kOAuth_AuthorizeURL];
    [dictService setObject:[NSString stringWithFormat:@"%@oauth/token", [[MSAppStore sharedStore] base_url_string]] forKey:kOAuth_TokenURL];
    [dictService setObject:[[MSAppStore sharedStore] client_id] forKey:kOAuth_ClientId];
    [dictService setObject:[[MSAppStore sharedStore] client_secret] forKey:kOAuth_Secret];
    [dictService setObject:@"amaroq://authorize" forKey:kOAuth_Callback];
    [dictService setObject:@"read write follow push" forKey:kOAuth_Scope];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DW_DID_CANCEL_LOGIN_NOTIFICATION object:nil];
    
    OAuthRequestController *oauthController = [[OAuthRequestController alloc] initWithDict:dictService];
    
    CGRect frame = [[[[UIApplication sharedApplication] topController] view] frame];
    frame.origin.y = 20.0f;
    
    oauthController.view.frame = frame;
    oauthController.delegate = self;
    [[[UIApplication sharedApplication] topController] presentViewController:oauthController animated:YES completion:^{
        
    }];
}


@end
