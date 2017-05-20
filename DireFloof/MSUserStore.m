//
//  MSUserStore.m
//  DireFloof
//
//  Created by John Gabelmann on 2/11/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "MSUserStore.h"
#import "MSAPIClient.h"
#import "MastodonConstants.h"
#import "MSAppStore.h"

@implementation MSUserStore

#pragma mark - Class Methods

+ (MSUserStore *)sharedStore
{
    static MSUserStore *sharedStore = nil;
    static dispatch_once_t storeToken;
    dispatch_once(&storeToken, ^{
       
        sharedStore = [[MSUserStore alloc] init];
    });
    
    return sharedStore;
}


+ (void)loadNextPage:(NSString *)nextPageUrl withCompletion:(void (^)(NSArray *, NSString *, NSError *))completion
{
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:[nextPageUrl stringByReplacingOccurrencesOfString:[[MSAppStore sharedStore] base_api_url_string] withString:@""] parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSHTTPURLResponse *response = ((NSHTTPURLResponse *)[task response]);
        NSString *nextPageUrl = [MSAPIClient getNextPageFromResponse:response];
        
        NSMutableArray *users = [@[] mutableCopy];
        
        for (NSDictionary *userJSON in responseObject) {
            
            MSAccount *user = [[MSAccount alloc] initWithParams:userJSON];
            [users addObject:user];
        }
        
        if (completion != nil) {
            completion(users, nextPageUrl, nil);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (completion != nil) {
            completion(nil, nil, error);
        }
    }];
}


#pragma mark - Instance Methods

- (NSString *)currentAccountString
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:MS_CURRENT_USER_KEY];
}


- (void)getCurrentUserWithCompletion:(void (^)(BOOL, MSAccount *, NSError *))completion
{
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:@"accounts/verify_credentials" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        self.currentUser = [[MSAccount alloc] initWithParams:responseObject];
        
        [[NSUserDefaults standardUserDefaults] setObject:self.currentUser.acct forKey:MS_CURRENT_USER_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];

        if (completion != nil) {
            completion(YES, self.currentUser, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (completion != nil) {
            completion(NO, nil, error);
        }
    }];
}


- (void)getUserWithId:(NSString *)userId withCompletion:(void (^)(BOOL, MSAccount *, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"accounts/%@", userId];
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:requestUrl parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        MSAccount *user = [[MSAccount alloc] initWithParams:responseObject];
        
        if (completion != nil) {
            completion(YES, user, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, nil, error);
        }
    }];
}


- (void)getFollowersForUserWithId:(NSString *)userId withCompletion:(void (^)(BOOL, NSArray *, NSString *, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"accounts/%@/followers", userId];
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:requestUrl parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSHTTPURLResponse *response = ((NSHTTPURLResponse *)[task response]);
        NSString *nextPageUrl = [MSAPIClient getNextPageFromResponse:response];
        
        NSMutableArray *users = [@[] mutableCopy];
        
        for (NSDictionary *userJSON in responseObject) {
            
            MSAccount *user = [[MSAccount alloc] initWithParams:userJSON];
            [users addObject:user];
        }
        
        if (completion != nil) {
            completion(YES, users, nextPageUrl, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, nil, nil, error);
        }
    }];
}


- (void)getFollowingForUserWithId:(NSString *)userId withCompletion:(void (^)(BOOL, NSArray *, NSString *, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"accounts/%@/following", userId];
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:requestUrl parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSHTTPURLResponse *response = ((NSHTTPURLResponse *)[task response]);
        NSString *nextPageUrl = [MSAPIClient getNextPageFromResponse:response];
        
        NSMutableArray *users = [@[] mutableCopy];
        
        for (NSDictionary *userJSON in responseObject) {
            
            MSAccount *user = [[MSAccount alloc] initWithParams:userJSON];
            [users addObject:user];
        }
        
        if (completion != nil) {
            completion(YES, users, nextPageUrl, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, nil, nil, error);
        }
    }];
}


- (void)getBlockedUsersWithCompletion:(void (^)(BOOL, NSArray *, NSString *, NSError *))completion
{
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:@"blocks" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSHTTPURLResponse *response = ((NSHTTPURLResponse *)[task response]);
        NSString *nextPageUrl = [MSAPIClient getNextPageFromResponse:response];

        
        NSMutableArray *users = [@[] mutableCopy];
        
        for (NSDictionary *userJSON in responseObject) {
            
            MSAccount *user = [[MSAccount alloc] initWithParams:userJSON];
            [users addObject:user];
        }
        
        if (completion != nil) {
            completion(YES, users, nextPageUrl, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, nil, nil, error);
        }
    }];
}


- (void)getMutedUsersWithCompletion:(void (^)(BOOL, NSArray *, NSString *, NSError *))completion
{
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:@"mutes" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSHTTPURLResponse *response = ((NSHTTPURLResponse *)[task response]);
        NSString *nextPageUrl = [MSAPIClient getNextPageFromResponse:response];
        
        
        NSMutableArray *users = [@[] mutableCopy];
        
        for (NSDictionary *userJSON in responseObject) {
            
            MSAccount *user = [[MSAccount alloc] initWithParams:userJSON];
            [users addObject:user];
        }
        
        if (completion != nil) {
            completion(YES, users, nextPageUrl, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, nil, nil, error);
        }
    }];
}


- (void)getRelationshipsToUsers:(NSArray *)userIds withCompletion:(void (^)(BOOL, NSDictionary *, NSError *))completion
{
    NSDictionary *params = @{@"id":userIds};
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:@"accounts/relationships" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completion != nil) {
            completion(YES, [responseObject firstObject], nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, nil, error);
        }
    }];
}


- (void)searchForUsersWithQuery:(NSString *)query withCompletion:(void (^)(BOOL, NSArray *, NSError *))completion
{
    NSDictionary *params = @{@"q":query, @"resolve":@"true"};
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:@"search" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        NSMutableArray *accounts = [@[] mutableCopy];

        id responseAccounts = [responseObject objectForKey:@"accounts"];

        if (responseAccounts != nil) {
            for (NSDictionary *accountJSON in responseAccounts) {
                MSAccount *account = [[MSAccount alloc] initWithParams:accountJSON];
            
                [accounts addObject:account];
            }
        }
        
        if (completion != nil) {
            completion(YES, accounts, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, nil, error);
        }
    }];
}


- (void)getUsersWhoRebloggedStatusWithId:(NSString *)statusId withCompletion:(void (^)(BOOL, NSArray *, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"statuses/%@/reblogged_by", statusId];
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:requestUrl parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSMutableArray *users = [@[] mutableCopy];
        
        for (NSDictionary *userJSON in responseObject) {
            
            MSAccount *user = [[MSAccount alloc] initWithParams:userJSON];
            [users addObject:user];
        }
        
        if (completion != nil) {
            completion(YES, users, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, nil, error);
        }
    }];
}


- (void)getUsersWhoFavoritedStatusWithId:(NSString *)statusId withCompletion:(void (^)(BOOL, NSArray *, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"statuses/%@/favourited_by", statusId];
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:requestUrl parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSMutableArray *users = [@[] mutableCopy];
        
        for (NSDictionary *userJSON in responseObject) {
            
            MSAccount *user = [[MSAccount alloc] initWithParams:userJSON];
            [users addObject:user];
        }
        
        if (completion != nil) {
            completion(YES, users, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, nil, error);
        }
    }];
}


- (void)followUserWithId:(NSString *)userId withCompletion:(void (^)(BOOL, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"accounts/%@/follow", userId];
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] POST:requestUrl parameters:nil constructingBodyWithBlock:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completion != nil) {
            completion(YES, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, error);
        }
    }];
}


- (void)unfollowUserWithId:(NSString *)userId withCompletion:(void (^)(BOOL, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"accounts/%@/unfollow", userId];
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] POST:requestUrl parameters:nil constructingBodyWithBlock:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completion != nil) {
            completion(YES, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, error);
        }
    }];
}


- (void)blockUserWithId:(NSString *)userId withCompletion:(void (^)(BOOL, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"accounts/%@/block", userId];
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] POST:requestUrl parameters:nil constructingBodyWithBlock:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completion != nil) {
            completion(YES, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, error);
        }
    }];
}


- (void)unblockUserWithId:(NSString *)userId withCompletion:(void (^)(BOOL, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"accounts/%@/unblock", userId];
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] POST:requestUrl parameters:nil constructingBodyWithBlock:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completion != nil) {
            completion(YES, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, error);
        }
    }];
}


- (void)muteUserWithId:(NSString *)userId withCompletion:(void (^)(BOOL, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"accounts/%@/mute", userId];
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] POST:requestUrl parameters:nil constructingBodyWithBlock:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completion != nil) {
            completion(YES, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, error);
        }
    }];

}


- (void)unmuteUserWithId:(NSString *)userId withCompletion:(void (^)(BOOL, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"accounts/%@/unmute", userId];
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] POST:requestUrl parameters:nil constructingBodyWithBlock:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completion != nil) {
            completion(YES, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, error);
        }
    }];
    
}


- (void)getRemoteUserWithLongformUsername:(NSString *)username withCompletion:(void (^)(BOOL, MSAccount *, NSError *))completion
{
    NSDictionary *params = @{@"uri": username};
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] POST:@"follows" parameters:params progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        MSAccount *user = [[MSAccount alloc] initWithParams:responseObject];
        
        if (completion != nil) {
            completion(YES, user, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, nil, error);
        }
    }];
}


- (void)getFollowRequestUsersWithCompletion:(void (^)(BOOL, NSArray *, NSString *, NSError *))completion
{
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] GET:@"follow_requests" parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSHTTPURLResponse *response = ((NSHTTPURLResponse *)[task response]);
        NSString *nextPageUrl = [MSAPIClient getNextPageFromResponse:response];
        
        
        NSMutableArray *users = [@[] mutableCopy];
        
        for (NSDictionary *userJSON in responseObject) {
            
            MSAccount *user = [[MSAccount alloc] initWithParams:userJSON];
            [users addObject:user];
        }
        
        if (completion != nil) {
            completion(YES, users, nextPageUrl, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, nil, nil, error);
        }
    }];
}


- (void)authorizeFollowRequestWithId:(NSString *)userId withCompletion:(void (^)(BOOL, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"follow_requests/%@/authorize", userId];
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] POST:requestUrl parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completion != nil) {
            completion(YES, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, error);
        }
    }];
}


- (void)rejectFollowRequestWithId:(NSString *)userId withCompletion:(void (^)(BOOL, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"follow_requests/%@/reject", userId];
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] POST:requestUrl parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
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
