//
//  MSAppStore.m
//  DireFloof
//
//  Created by John Gabelmann on 2/7/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "MSAppStore.h"
#import "MastodonConstants.h"
#import "MSAPIClient.h"
#import "MSAuthStore.h"

@interface MSAppStore ()

@property (nonatomic, assign, readwrite) BOOL isRegistered;
@property (nonatomic, strong, readwrite) NSString *client_id;
@property (nonatomic, strong, readwrite) NSString *client_secret;
@property (nonatomic, strong, readwrite) NSString *base_url_string;
@property (nonatomic, strong, readwrite) NSString *base_api_url_string;
@property (nonatomic, strong, readwrite) NSString *base_media_url_string;
@property (nonatomic, strong, readwrite) NSString *instance;

@end

@implementation MSAppStore

#pragma mark - Getter/Setter Overrides

- (BOOL)isRegistered
{
    return self.client_id != nil && self.client_secret != nil;
}


#pragma mark - Class Methods

+ (MSAppStore *)sharedStore
{
    static MSAppStore *sharedStore = nil;
    static dispatch_once_t storeToken;
    dispatch_once(&storeToken, ^{
        
        sharedStore = [[MSAppStore alloc] init];
    });
    
    return sharedStore;
}


#pragma mark - Initializers

- (id)init
{
    self = [super init];
    if (self) {
        
        self.client_id = [[NSUserDefaults standardUserDefaults] objectForKey:MS_CLIENT_ID_KEY];
        self.client_secret = [[NSUserDefaults standardUserDefaults] objectForKey:MS_CLIENT_SECRET_KEY];
        self.base_url_string = [[NSUserDefaults standardUserDefaults] objectForKey:MS_BASE_URL_STRING_KEY];
        self.base_api_url_string = [[NSUserDefaults standardUserDefaults] objectForKey:MS_BASE_API_URL_STRING_KEY];
        self.base_media_url_string = [[NSUserDefaults standardUserDefaults] objectForKey:MS_BASE_MEDIA_URL_STRING_KEY];
        self.instance = [[NSUserDefaults standardUserDefaults] objectForKey:MS_INSTANCE_KEY];
    }
    
    return self;
}


#pragma mark - Instance Methods

- (void)setMastodonInstance:(NSString *)instance
{
    NSString *instanceName = [[instance componentsSeparatedByString:@"//"] lastObject];
    
    if (!instanceName.length) {
        instanceName = @"mastodon.social";
    }
    
    self.instance = instanceName;
    self.base_url_string = [NSString stringWithFormat:@"https://%@/", instanceName];
    self.base_api_url_string = [self.base_url_string stringByAppendingString:@"api/v1/"];
    self.base_media_url_string = [NSString stringWithFormat:@"https://files.%@/", instanceName];
    
    NSString *previousInstance = [[NSUserDefaults standardUserDefaults] objectForKey:MS_INSTANCE_KEY];
    
    [[NSUserDefaults standardUserDefaults] setObject:self.base_url_string forKey:MS_BASE_URL_STRING_KEY];
    [[NSUserDefaults standardUserDefaults] setObject:self.base_api_url_string forKey:MS_BASE_API_URL_STRING_KEY];
    [[NSUserDefaults standardUserDefaults] setObject:self.base_media_url_string forKey:MS_BASE_MEDIA_URL_STRING_KEY];
    [[NSUserDefaults standardUserDefaults] setObject:self.instance forKey:MS_INSTANCE_KEY];
    
    if (previousInstance) {
        if (![previousInstance isEqualToString:self.instance]) {
            self.client_id = nil;
            self.client_secret = nil;
            
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:MS_CLIENT_ID_KEY];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:MS_CLIENT_SECRET_KEY];
        }
    }
    else
    {
        AFOAuthCredential *credential = [AFOAuthCredential retrieveCredentialWithIdentifier:[self base_api_url_string]];
        
        if (credential) {
            [[MSAuthStore sharedStore] setCredential:nil];
        }
        
        [AFOAuthCredential deleteCredentialWithIdentifier:[self base_api_url_string]];
    }
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)registerApp:(void (^)(BOOL))completion
{
    if (self.isRegistered) {
        if (completion != nil) {
            completion(self.isRegistered);
        }
    }
    else
    {
        NSDictionary *params = @{@"client_name": @"Amaroq",
                                 @"redirect_uris": @"urn:ietf:wg:oauth:2.0:oob",
                                 @"scopes": @"read write follow",
                                 @"website": @"https://appsto.re/us/OfFxib.i"};
        
        NSString *requestUrl = [NSString stringWithFormat:@"%@%@", self.base_api_url_string, @"apps"];
        
        [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] POST:requestUrl parameters:params constructingBodyWithBlock:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {

            self.client_id = [responseObject objectForKey:@"client_id"];
            self.client_secret = [responseObject objectForKey:@"client_secret"];
            
            [[NSUserDefaults standardUserDefaults] setObject:self.client_id forKey:MS_CLIENT_ID_KEY];
            [[NSUserDefaults standardUserDefaults] setObject:self.client_secret forKey:MS_CLIENT_SECRET_KEY];
            
            if (completion != nil) {
                completion(self.isRegistered);
            }
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            if (completion != nil) {
                completion(self.isRegistered);
            }
        }];
    }
}

@end
