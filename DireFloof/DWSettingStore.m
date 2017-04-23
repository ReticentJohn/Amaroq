//
//  DWSettingStore.m
//  DireFloof
//
//  Created by John Gabelmann on 3/8/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <SDWebImage/SDImageCache.h>
#import <AFNetworking/AFImageDownloader.h>
#import <FCFileManager/FCFileManager.h>
#import "DWSettingStore.h"
#import "DWConstants.h"

@implementation DWSettingStore

#pragma mark - Class Methods

+ (DWSettingStore *)sharedStore
{
    static DWSettingStore *sharedStore = nil;
    static dispatch_once_t storeToken;
    dispatch_once(&storeToken, ^{
        
        sharedStore = [[DWSettingStore alloc] init];
    });
    
    return sharedStore;
}


#pragma mark - Initializers

- (id)init
{
    self = [super init];
    
    if (self) {
                
        _alwaysPrivate = [[NSUserDefaults standardUserDefaults] boolForKey:DW_SETTING_ALWAYS_PRIVATE_KEY];
        _alwaysPublic = [[NSUserDefaults standardUserDefaults] boolForKey:DW_SETTING_ALWAYS_PUBLIC_KEY];
        self.awooMode = [[NSUserDefaults standardUserDefaults] boolForKey:DW_SETTING_AWOO_MODE_KEY];
        self.disableGifPlayback = [[NSUserDefaults standardUserDefaults] boolForKey:DW_SETTING_GIF_AUTOPLAY_KEY];
        self.newFollowerNotifications = ![[NSUserDefaults standardUserDefaults] boolForKey:DW_SETTING_NEW_FOLLOWERS_OFF_KEY];
        self.favoriteNotifications = ![[NSUserDefaults standardUserDefaults] boolForKey:DW_SETTING_FAVORITES_OFF_KEY];
        self.mentionNotifications = ![[NSUserDefaults standardUserDefaults] boolForKey:DW_SETTING_MENTIONS_OFF_KEY];
        self.boostNotifications = ![[NSUserDefaults standardUserDefaults] boolForKey:DW_SETTING_BOOSTS_OFF_KEY];
        self.showLocalTimeline = [[NSUserDefaults standardUserDefaults] boolForKey:DW_SETTING_PUBLIC_SHOW_LOCAL_KEY];
    }
    
    return self;
}


#pragma mark - Getter/Setter Overrides

- (void)setAlwaysPrivate:(BOOL)alwaysPrivate
{
    _alwaysPrivate = alwaysPrivate;
    
    if (_alwaysPrivate == YES) {
        _alwaysPublic = NO;
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:_alwaysPrivate forKey:DW_SETTING_ALWAYS_PRIVATE_KEY];
    [[NSUserDefaults standardUserDefaults] setBool:_alwaysPublic forKey:DW_SETTING_ALWAYS_PUBLIC_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)setAlwaysPublic:(BOOL)alwaysPublic
{
    _alwaysPublic = alwaysPublic;
    
    if (_alwaysPublic == YES) {
        _alwaysPrivate = NO;
    }
    
    [[NSUserDefaults standardUserDefaults] setBool:_alwaysPrivate forKey:DW_SETTING_ALWAYS_PRIVATE_KEY];
    [[NSUserDefaults standardUserDefaults] setBool:_alwaysPublic forKey:DW_SETTING_ALWAYS_PUBLIC_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}
     

- (void)setAwooMode:(BOOL)awooMode
{
    _awooMode = awooMode;
    
    [[NSUserDefaults standardUserDefaults] setBool:awooMode forKey:DW_SETTING_AWOO_MODE_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)setDisableGifPlayback:(BOOL)disableGifPlayback
{
    _disableGifPlayback = disableGifPlayback;
    
    [[NSUserDefaults standardUserDefaults] setBool:disableGifPlayback forKey:DW_SETTING_GIF_AUTOPLAY_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)setNewFollowerNotifications:(BOOL)newFollowerNotifications
{
    _newFollowerNotifications = newFollowerNotifications;
    
    [[NSUserDefaults standardUserDefaults] setBool:!newFollowerNotifications forKey:DW_SETTING_NEW_FOLLOWERS_OFF_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)setFavoriteNotifications:(BOOL)favoriteNotifications
{
    _favoriteNotifications = favoriteNotifications;
    
    [[NSUserDefaults standardUserDefaults] setBool:!favoriteNotifications forKey:DW_SETTING_FAVORITES_OFF_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)setMentionNotifications:(BOOL)mentionNotifications
{
    _mentionNotifications = mentionNotifications;
    
    [[NSUserDefaults standardUserDefaults] setBool:!mentionNotifications forKey:DW_SETTING_MENTIONS_OFF_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)setBoostNotifications:(BOOL)boostNotifications
{
    _boostNotifications = boostNotifications;
    
    [[NSUserDefaults standardUserDefaults] setBool:!boostNotifications forKey:DW_SETTING_BOOSTS_OFF_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)setShowLocalTimeline:(BOOL)showLocalTimeline
{
    _showLocalTimeline = showLocalTimeline;
    
    [[NSUserDefaults standardUserDefaults] setBool:showLocalTimeline forKey:DW_SETTING_PUBLIC_SHOW_LOCAL_KEY];
}


#pragma mark - Instance Methods

- (NSString *)cacheSizeString
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths objectAtIndex:0];
    BOOL isDir = NO;
    
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    
    NSNumber *cacheSize = [FCFileManager sizeOfDirectoryAtPath:cachePath];
    
    AFImageDownloader *imageDownloader = [AFImageDownloader defaultInstance];
    NSURLCache *urlCache = imageDownloader.sessionManager.session.configuration.URLCache;
    
    NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
    
    return [formatter stringFromByteCount:cacheSize.longLongValue + [[NSURLCache sharedURLCache] currentDiskUsage] + [urlCache currentDiskUsage] + [[SDImageCache sharedImageCache] getSize]];
}


- (void)purgeCaches
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachePath = [paths objectAtIndex:0];
    BOOL isDir = NO;
    
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DW_WILL_PURGE_CACHE_NOTIFICATION object:nil];
    
    [FCFileManager removeFilesInDirectoryAtPath:cachePath];
    
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
    
    AFImageDownloader *imageDownloader = [AFImageDownloader defaultInstance];
    NSURLCache *urlCache = imageDownloader.sessionManager.session.configuration.URLCache;
    
    [urlCache removeAllCachedResponses];
    [imageDownloader.imageCache removeAllImages];
    [[SDImageCache sharedImageCache] clearDisk];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:DW_DID_PURGE_CACHE_NOTIFICATION object:nil];
}


@end
