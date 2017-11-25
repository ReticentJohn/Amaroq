//
//  MSNotificationStore.m
//  DireFloof
//
//  Created by John Gabelmann on 2/8/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "MSNotificationStore.h"
#import "MSAPIClient.h"
#import "MSAppStore.h"

@implementation MSNotificationStore

#pragma mark - Class Methods

+ (MSNotificationStore *)sharedStore
{
    static MSNotificationStore *sharedStore = nil;
    static dispatch_once_t storeToken;
    dispatch_once(&storeToken, ^{
        
        sharedStore = [[MSNotificationStore alloc] init];
    });
    
    return sharedStore;
}


#pragma mark - Instance Methods

- (void)getNotificationsSinceId:(NSString *)notificationId withCompletion:(void (^)(BOOL, MSTimeline *, NSError *))completion
{
    NSDictionary *params = nil;
    
    if (notificationId) {
        params = @{@"since_id": notificationId};
    }
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:@"notifications" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSHTTPURLResponse *response = ((NSHTTPURLResponse *)[task response]);
        NSString *nextPageUrl = [MSAPIClient getNextPageFromResponse:response];
        NSString *prevPageUrl = [MSAPIClient getPreviousPageFromResponse:response];
        
        MSTimeline *timeline = [[MSTimeline alloc] initWithNotifications:responseObject olderPageUrl:nextPageUrl newerPageUrl:prevPageUrl];
        
        if (timeline.statuses.count) {
            [[NSUserDefaults standardUserDefaults] setObject:[[timeline.statuses firstObject] _id] forKey:MS_LAST_NOTIFICATION_ID_KEY];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
        
        if (completion != nil) {
            completion(YES, timeline, nil);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, nil, error);
        }
    }];
}


- (void)clearNotificationsWithCompletion:(void (^)(BOOL, NSError *))completion
{
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] POST:@"notifications/clear" parameters:nil constructingBodyWithBlock:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completion != nil) {
            completion(YES, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, error);
        }
    }];
}

@end
