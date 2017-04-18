//
//  MSTimeline.m
//  DireFloof
//
//  Created by John Gabelmann on 2/12/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "MSTimeline.h"
#import "MSAPIClient.h"
#import "MSNotification.h"
#import "MSAppStore.h"
#import "DWSettingStore.h"

@interface MSTimeline ()

@property (nonatomic, strong, readwrite) NSMutableArray *statuses;
@property (nonatomic, strong, readwrite) NSString *nextPageUrl;
@property (nonatomic, assign) BOOL isNotificationTimeline;

@end

@implementation MSTimeline

#pragma mark - Initializers

- (id)initWithStatuses:(NSArray *)statuses nextPageUrl:(NSString *)url
{
    self = [super init];
    
    if (self)
    {
        self.statuses = [@[] mutableCopy];
        
        for (NSDictionary *statusJSON in statuses) {
            
            MSStatus *status = [[MSStatus alloc] initWithParams:statusJSON];
            [self.statuses addObject:status];
        }
        
        self.nextPageUrl = url ? [url stringByReplacingOccurrencesOfString:[[MSAppStore sharedStore] base_api_url_string] withString:@""] : nil;
    }
    
    return self;
}


- (id)initWithNotifications:(NSArray *)notifications nextPageUrl:(NSString *)url
{
    self = [super init];
    
    if (self)
    {
        self.statuses = [@[] mutableCopy];
        
        for (NSDictionary *notificationJSON in notifications) {
            
            MSNotification *status = [[MSNotification alloc] initWithParams:notificationJSON];
            [self.statuses addObject:status];
        }
        
        self.nextPageUrl = [url stringByReplacingOccurrencesOfString:[[MSAppStore sharedStore] base_api_url_string] withString:@""];
        
        self.isNotificationTimeline = YES;
    }
    
    return self;
}


#pragma mark - Instance Methods

- (void)loadNextPageWithCompletion:(void (^)(BOOL, NSError *))completion
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:self.nextPageUrl parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                for (NSDictionary *statusJSON in responseObject) {
                    
                    if (self.isNotificationTimeline) {
                        MSNotification *status = [[MSNotification alloc] initWithParams:statusJSON];
                        [self.statuses addObject:status];
                    }
                    else
                    {
                        MSStatus *status = [[MSStatus alloc] initWithParams:statusJSON];
                        [self.statuses addObject:status];
                    }
                }
                
                NSHTTPURLResponse *response = ((NSHTTPURLResponse *)[task response]);
                NSString *nextPageUrl = [MSAPIClient getNextPageFromResponse:response];
                
                if (nextPageUrl) {
                    
                    nextPageUrl = [nextPageUrl stringByReplacingOccurrencesOfString:[[MSAppStore sharedStore] base_api_url_string] withString:@""];
                    
                    self.nextPageUrl = [nextPageUrl isEqualToString:self.nextPageUrl] ? nil : nextPageUrl;
                }
                else
                {
                    self.nextPageUrl = nil;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion != nil) {
                        completion(YES, nil);
                    }
                });
            });
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion != nil) {
                    completion(NO, error);
                }
            });

        }];
    });
}


- (void)purgeLocalStatus:(MSStatus *)deletedStatus
{
    [self.statuses removeObject:deletedStatus];
}


- (void)purgeLocalStatusesByUser:(MSAccount *)blockedUser
{
    [self.statuses filterUsingPredicate:[NSPredicate predicateWithFormat:@"account._id != %@", blockedUser._id]];
}


- (void)filterForNotificationSettings
{
    // This filter method is for notifications only
    if (!self.isNotificationTimeline) {
        return;
    }
    
    NSMutableArray *notificationFilters = [@[] mutableCopy];
    
    if (![[DWSettingStore sharedStore] newFollowerNotifications]) {
        [notificationFilters addObject:MS_NOTIFICATION_TYPE_FOLLOW];
    }
    
    if (![[DWSettingStore sharedStore] boostNotifications]) {
        [notificationFilters addObject:MS_NOTIFICATION_TYPE_REBLOG];
    }
    
    if (![[DWSettingStore sharedStore] mentionNotifications]) {
        [notificationFilters addObject:MS_NOTIFICATION_TYPE_MENTION];
    }
    
    if (![[DWSettingStore sharedStore] favoriteNotifications]) {
        [notificationFilters addObject:MS_NOTIFICATION_TYPE_FAVORITE];
    }
    
    if (notificationFilters.count) {
        [self.statuses filterUsingPredicate:[NSPredicate predicateWithFormat:@"!(type IN %@)", notificationFilters]];
    }
}

@end
