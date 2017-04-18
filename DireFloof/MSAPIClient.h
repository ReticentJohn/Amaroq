//
//  MSAPIClient.h
//  DireFloof
//
//  Created by John Gabelmann on 2/7/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import <AFNetworking/AFHTTPSessionManager.h>
#import <AFOAuth2Manager/AFOAuth2Manager.h>
#import <AFHTTPRequestSerializer+OAuth2.h>

@interface MSAPIClient : AFHTTPSessionManager

#pragma mark - Properties

@property (nonatomic, strong) AFOAuth2Manager *oAuth2Manager;

#pragma mark - Class Methods

+ (MSAPIClient *)sharedClientWithBaseAPI:(NSString *)baseAPI;
+ (NSString *)getNextPageFromResponse:(NSHTTPURLResponse *)response;

@end
