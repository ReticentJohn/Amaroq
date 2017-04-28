//
//  DWMediaStore.m
//  DireFloof
//
//  Created by John Gabelmann on 3/6/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <AFNetworking/AFNetworking.h>
#import "DWMediaStore.h"
#import "UIImage+color.h"
#import "DWConstants.h"

@interface DWMediaStore ()

@property (nonatomic, strong) AFURLSessionManager *mediaManager;
@property (nonatomic, strong) UIImage *placeholderImage;

@end

@implementation DWMediaStore

#pragma mark - Class Methods

+ (DWMediaStore *)sharedStore
{
    static DWMediaStore *sharedStore = nil;
    static dispatch_once_t storeToken;
    dispatch_once(&storeToken, ^{
        
        sharedStore = [[DWMediaStore alloc] init];
    });
    
    return sharedStore;
}


#pragma mark - Initializers

- (id)init
{
    self = [super init];
    
    if (self) {
        self.mediaManager = [[AFURLSessionManager alloc] init];
        self.placeholderImage = [UIImage imageWithColor:DW_BACKGROUND_COLOR];
    }
    
    return self;
}


#pragma mark - Instance Methods

- (void)downloadGifvMedia:(NSURL *)mediaURL withCompletion:(void (^)(BOOL, NSURL *, NSError *))completion
{
    
    NSString *filePath = [self filePathForMediaURL:mediaURL];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        
        if (completion) {
            completion(YES, [NSURL fileURLWithPath:filePath], nil);
        }
    }
    else
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [[self.mediaManager downloadTaskWithRequest:[NSURLRequest requestWithURL:mediaURL] progress:nil destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
                return [NSURL fileURLWithPath:filePath];
            } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (!error) {
                        if (completion) {
                            completion(YES, filePath, nil);
                        }
                    }
                    else
                    {
                        if (completion) {
                            completion(NO, nil, error);
                        }
                    }
                });
                
            }] resume];
        });
    }
}


- (NSURL *)cachedURLForGifvMedia:(NSURL *)mediaURL
{
    NSString *filePath = [self filePathForMediaURL:mediaURL];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        return [NSURL fileURLWithPath:filePath];
    }
    
    return nil;
}


#pragma mark - Private Methods

- (NSString *)filePathForMediaURL:(NSURL *)mediaURL
{
    NSString *mediaIdentifier = [[[[mediaURL absoluteString] componentsSeparatedByString:@"?"] lastObject] stringByAppendingString:@".mp4"];
    
    if ([mediaIdentifier containsString:@"/"]) {
        mediaIdentifier = [[mediaURL.path componentsSeparatedByString:@"/"] componentsJoinedByString:@""];
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths objectAtIndex:0];
    BOOL isDir = NO;
    
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    
    NSString *filePath = [cachePath stringByAppendingPathComponent:mediaIdentifier];
    
    return filePath;
}

@end
