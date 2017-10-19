//
//  OAuthRequestController.m
//  LROAuth2Demo
//
//  Created by Luke Redpath on 01/06/2010.
//  Copyright 2010 LJR Software Limited. All rights reserved.
//
// Edited by Trong Dinh

#import "OAuthRequestController.h"
#import "LROAuth2Client.h"
#import "LROAuth2AccessToken.h"
#import "Validations.h"

/*
 * you will need to create this from OAuthCredentials-Example.h
 *
 */

@implementation OAuthRequestController

@synthesize webView;

#pragma mark - init

- (id)initWithDict:(NSDictionary *)dict {
    if (self = [super initWithNibName:@"OAuthRequestController" bundle:[NSBundle bundleForClass:[OAuthRequestController class]]]) {
        oauthClient = [[LROAuth2Client alloc] initWithClientID:[dict objectForKey:kOAuth_ClientId]
                                                        secret:[dict objectForKey:kOAuth_Secret]
                                                   redirectURL:[NSURL URLWithString:[dict objectForKey:kOAuth_Callback]]];
        
        oauthClient.userURL  = [NSURL URLWithString:[dict objectForKey:kOAuth_AuthorizeURL]];
        oauthClient.tokenURL = [NSURL URLWithString:[dict objectForKey:kOAuth_TokenURL]];
        oauthClient.scope = [dict objectForKey:kOAuth_Scope];
        
        [self initObj];
        _dictValues = [NSMutableDictionary dictionaryWithDictionary:dict];
    }
    
    return self;
}

- (void)initObj {
    oauthClient.debug = YES;
    oauthClient.delegate = self;
    
    self.modalPresentationStyle = UIModalPresentationFormSheet;
    self.modalTransitionStyle   = UIModalTransitionStyleCrossDissolve;
}

#pragma mark - view life cycle

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.webView = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSDictionary *params = [NSDictionary dictionaryWithObject:@"touch" forKey:@"display"];
    [oauthClient authorizeUsingWebView:self.webView additionalParameters:params];
}

- (void)dealloc
{
    oauthClient.delegate = nil;
    webView.delegate = nil;
}

- (void)refreshAccessToken:(LROAuth2AccessToken *)accessToken
{
    [oauthClient refreshAccessToken:accessToken];
}

- (void)sendBackOAuth2Data:(LROAuth2AccessToken *)client {
    if ([_delegate respondsToSelector:@selector(didAuthorized:)]) {
        [_dictValues setObject:VALID(client.accessToken, NSString)?client.accessToken:@"" forKey:kOAuth_AccessToken];
        [_dictValues setObject:VALID(client.refreshToken, NSString)?client.refreshToken:@"" forKey:kOAuth_RefreshToken];
        [_dictValues setObject:VALID(client.expiresAt, NSDate)?client.expiresAt:@"" forKey:kOAuth_ExpiredDate];
        
        [_delegate didAuthorized:_dictValues];
    }

}

#pragma mark - IBAction methods

- (IBAction)btnCancelTouched:(id)sender {
    if ([_delegate respondsToSelector:@selector(didCancel)]) {
        [_delegate didCancel];
        
    } else {
        [self dismissViewControllerAnimated:YES completion:^{

        }];
    }
}

#pragma mark -
#pragma mark LROAuth2ClientDelegate methods

- (void)oauthClientDidReceiveAccessToken:(LROAuth2Client *)client
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OAuthReceivedAccessTokenNotification" object:client.accessToken];
    [self sendBackOAuth2Data:client.accessToken];
    
    [self btnCancelTouched:nil];
}

- (void)oauthClientDidRefreshAccessToken:(LROAuth2Client *)client
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"OAuthRefreshedAccessTokenNotification" object:client.accessToken];
    [self sendBackOAuth2Data:client.accessToken];
    
    [self btnCancelTouched:nil];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    [indicator stopAnimating];
    return YES;
}

@end
