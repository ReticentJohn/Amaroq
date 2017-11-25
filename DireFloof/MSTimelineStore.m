//
//  MSTimelineStore.m
//  DireFloof
//
//  Created by John Gabelmann on 2/7/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "MSTimelineStore.h"
#import "MSAPIClient.h"
#import "MSAppStore.h"

@interface MSTimelineStore ()

@property (nonatomic, assign) MSTimelineType timelineType;
@property (nonatomic, strong) NSString *hashtag;

@end

@implementation MSTimelineStore

#pragma mark - Class Methods

+ (MSTimelineStore *)sharedStore
{
    static MSTimelineStore *sharedStore = nil;
    static dispatch_once_t storeToken;
    dispatch_once(&storeToken, ^{
        
        sharedStore = [[MSTimelineStore alloc] init];
    });
    
    return sharedStore;
}


#pragma mark - Instance Methods

- (void)getTimelineForTimelineType:(MSTimelineType)timelineType withCompletion:(void (^)(BOOL, MSTimeline *, NSError *))completion
{
    self.timelineType = timelineType;
    
    switch (timelineType) {
        case MSTimelineTypeHome:
            [self getHomeTimelineWithCompletion:completion];
            break;
        case MSTimelineTypePublic:
        case MSTimelineTypeLocal:
            [self getPublicTimeline:timelineType == MSTimelineTypeLocal withCompletion:completion];
            break;
        case MSTimelineTypeHashtag:
            [self getHashtagTimelineForHashtag:self.hashtag withCompletion:completion];
            break;
        default:
        {
            NSError *error = [NSError errorWithDomain:@"com.keyboardfloofs.DireFloof" code:500 userInfo:@{NSLocalizedFailureReasonErrorKey: @"Invalid timeline type"}];
            
            if (completion != nil) {
                completion(NO, nil, error);
            }
        }
            break;
    }
}


- (void)getHashtagTimelineWithHashtag:(NSString *)hashtag withCompletion:(void (^)(BOOL, MSTimeline *, NSError *))completion
{
    self.hashtag = hashtag;
    [self getTimelineForTimelineType:MSTimelineTypeHashtag withCompletion:completion];
}


#pragma mark - Private Methods

- (void)getHomeTimelineWithCompletion:(void (^)(BOOL, MSTimeline *, NSError *))completion
{
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:@"timelines/home" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSHTTPURLResponse *response = ((NSHTTPURLResponse *)[task response]);
        NSString *nextPageUrl = [MSAPIClient getNextPageFromResponse:response];
        NSString *prevPageUrl = [MSAPIClient getPreviousPageFromResponse:response];
        
        MSTimeline *timeline = [[MSTimeline alloc] initWithStatuses:responseObject olderPageUrl:nextPageUrl newerPageUrl:prevPageUrl];
        
        if (completion != nil) {
            completion(YES, timeline, nil);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (completion != nil) {
            completion(NO, nil, error);
        }
    }];
}


- (void)getPublicTimeline:(BOOL)isLocal withCompletion:(void (^)(BOOL, MSTimeline *, NSError *))completion
{
    NSDictionary *params = nil;
    
    if (isLocal) {
        params = @{@"local": @(YES)};
    }
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:@"timelines/public" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSHTTPURLResponse *response = ((NSHTTPURLResponse *)[task response]);
        NSString *nextPageUrl = [MSAPIClient getNextPageFromResponse:response];
        NSString *prevPageUrl = [MSAPIClient getPreviousPageFromResponse:response];
        
        MSTimeline *timeline = [[MSTimeline alloc] initWithStatuses:responseObject olderPageUrl:nextPageUrl newerPageUrl:prevPageUrl];
        
        if (completion != nil) {
            completion(YES, timeline, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, nil, error);
        }
    }];
}


- (void)getHashtagTimelineForHashtag:(NSString *)hashtag withCompletion:(void (^)(BOOL, MSTimeline *, NSError *))completion
{
    NSString *requestUrl = [[NSString stringWithFormat:@"timelines/tag/%@", hashtag] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:requestUrl parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSHTTPURLResponse *response = ((NSHTTPURLResponse *)[task response]);
        NSString *nextPageUrl = [MSAPIClient getNextPageFromResponse:response];
        NSString *prevPageUrl = [MSAPIClient getPreviousPageFromResponse:response];
        
        MSTimeline *timeline = [[MSTimeline alloc] initWithStatuses:responseObject olderPageUrl:nextPageUrl newerPageUrl:prevPageUrl];
        
        if (completion != nil) {
            completion(YES, timeline, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, nil, error);
        }
    }];
}


- (void)getStatusesForUserId:(NSString *)userId withCompletion:(void (^)(BOOL, MSTimeline *, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"accounts/%@/statuses", userId];
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:requestUrl parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSHTTPURLResponse *response = ((NSHTTPURLResponse *)[task response]);
        NSString *nextPageUrl = [MSAPIClient getNextPageFromResponse:response];
        NSString *prevPageUrl = [MSAPIClient getPreviousPageFromResponse:response];
        
        MSTimeline *timeline = [[MSTimeline alloc] initWithStatuses:responseObject olderPageUrl:nextPageUrl newerPageUrl:prevPageUrl];
        
        if (completion != nil) {
            completion(YES, timeline, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, nil, error);
        }
    }];
}


- (void)getFavoriteStatusesWithCompletion:(void (^)(BOOL, MSTimeline *, NSError *))completion
{
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:@"favourites" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSHTTPURLResponse *response = ((NSHTTPURLResponse *)[task response]);
        NSString *nextPageUrl = [MSAPIClient getNextPageFromResponse:response];
        NSString *prevPageUrl = [MSAPIClient getPreviousPageFromResponse:response];
        
        MSTimeline *timeline = [[MSTimeline alloc] initWithStatuses:responseObject olderPageUrl:nextPageUrl newerPageUrl:prevPageUrl];
        
        if (completion != nil) {
            completion(YES, timeline, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, nil, error);
        }
    }];
}


- (void)getThreadForStatus:(MSStatus *)status withCompletion:(void (^)(BOOL, MSTimeline *, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"statuses/%@/context", status._id];
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:requestUrl parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSMutableArray *statuses = [@[] mutableCopy];
        
        [statuses addObjectsFromArray:[responseObject objectForKey:@"ancestors"]];
        [statuses addObject:[status toJSON]];
        [statuses addObjectsFromArray:[responseObject objectForKey:@"descendants"]];
        
        MSTimeline *timeline = [[MSTimeline alloc] initWithStatuses:statuses olderPageUrl:nil newerPageUrl:nil];
        
        if (completion != nil) {
            completion(YES, timeline, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, nil, error);
        }
    }];
}

@end
