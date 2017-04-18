//
//  MSAPIClient.m
//  DireFloof
//
//  Created by John Gabelmann on 2/7/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "MSAPIClient.h"
#import "MastodonConstants.h"
#import "MSAppStore.h"
#import "MSAuthStore.h"

@implementation MSAPIClient

#pragma mark - Initialization

- (id)initWithBaseURL:(NSURL *)url sessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    self = [super initWithBaseURL:url sessionConfiguration:configuration];
    if (self) {
        
        self.requestSerializer.networkServiceType = NSURLNetworkServiceTypeBackground;
        
        NSOperationQueue *operationQueue = self.operationQueue;
        
        // Monitor reachability so we dont spin stupidity
        [self.reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
            
            switch (status) {
                case AFNetworkReachabilityStatusReachableViaWWAN:
                case AFNetworkReachabilityStatusReachableViaWiFi:
                    [operationQueue setSuspended:NO];
                    break;
                case AFNetworkReachabilityStatusNotReachable:
                default:
                    [operationQueue setSuspended:YES];
                    break;
            }
        }];
        
    }
    
    return self;
}


#pragma mark - Class Methods

+ (MSAPIClient *)sharedClientWithBaseAPI:(NSString *)baseAPI
{
    NSURL *baseURL = [NSURL URLWithString:baseAPI];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.TLSMaximumSupportedProtocol = kTLSProtocol12;
    configuration.HTTPMaximumConnectionsPerHost = 3;
    configuration.timeoutIntervalForRequest = 900.0f;
    
    MSAPIClient *sharedClient = [[MSAPIClient alloc] initWithBaseURL:baseURL sessionConfiguration:configuration];
    
    [sharedClient.reachabilityManager startMonitoring];
    
    if ([[MSAppStore sharedStore] isRegistered] && !sharedClient.oAuth2Manager) {
        
        sharedClient.oAuth2Manager = [[AFOAuth2Manager alloc] initWithBaseURL:[NSURL URLWithString:baseAPI] clientID:[[MSAppStore sharedStore] client_id] secret:[[MSAppStore sharedStore] client_secret]];
        sharedClient.oAuth2Manager.useHTTPBasicAuthentication = NO;
    }
    
    if ([[MSAuthStore sharedStore] isLoggedIn]) {
        
        [sharedClient.requestSerializer setAuthorizationHeaderFieldWithCredential:[[MSAuthStore sharedStore] credential]];
    }
    
    return sharedClient;
}


+ (NSString *)getNextPageFromResponse:(NSHTTPURLResponse *)response
{
    NSDictionary *headers = [response allHeaderFields];
    NSString *nextPageUrl = nil;
    
    if ([headers objectForKey:@"Link"]) {
        
        NSArray *components = [[headers objectForKey:@"Link"] componentsSeparatedByString:@", "];
        
        if ([[components firstObject] containsString:@"next"]) {
            
            NSString *component = [components firstObject];
            NSRange beginningTrim = [component rangeOfString:@"<"];
            NSRange endingTrim = [component rangeOfString:@">"];
            NSRange nextPageRange = NSMakeRange(beginningTrim.location + beginningTrim.length, endingTrim.location - beginningTrim.location - beginningTrim.length);
            
            nextPageUrl = [component substringWithRange:nextPageRange];
        }
        
    }
    
    return nextPageUrl;
}

@end
