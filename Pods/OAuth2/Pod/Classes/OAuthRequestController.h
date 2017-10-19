//
//  OAuthRequestController.h
//  LROAuth2Demo
//
//  Created by Luke Redpath on 01/06/2010.
//  Copyright 2010 LJR Software Limited. All rights reserved.
//
// Edited by Trong Dinh

#import <UIKit/UIKit.h>
#import "LROAuth2ClientDelegate.h"
#import "OAuthKey.h"

@protocol OAuthRequestControllerDelegate <NSObject>

@required
- (void)didAuthorized:(NSDictionary *)dictResponse;

@optional
- (void)didCancel;

@end

@class LROAuth2Client;
@class LROAuth2AccessToken;
@interface OAuthRequestController : UIViewController <LROAuth2ClientDelegate> {
    LROAuth2Client *oauthClient;
    UIWebView *webView;
    __weak IBOutlet UIActivityIndicatorView *indicator;
}

@property (nonatomic, assign) id<OAuthRequestControllerDelegate> delegate;
@property (nonatomic, strong) NSMutableDictionary *dictValues;
@property (nonatomic, retain) IBOutlet UIWebView *webView;

- (id)initWithDict:(NSDictionary *)dict;
- (IBAction)btnCancelTouched:(id)sender;
- (void)refreshAccessToken:(LROAuth2AccessToken *)accessToken;

@end
