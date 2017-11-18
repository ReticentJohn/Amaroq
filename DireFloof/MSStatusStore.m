//
//  MSStatusStore.m
//  DireFloof
//
//  Created by John Gabelmann on 2/8/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Photos/Photos.h>
#import "MSStatusStore.h"
#import "MSAPIClient.h"
#import "MSAppStore.h"

@interface MSStatusStore ()

@property (nonatomic, copy) void (^progressBlock)(CGFloat progress);

@end

@implementation MSStatusStore

#pragma mark - Constants

static NSUInteger maxUploadSize = 8 * 1024 * 1024;

#pragma mark - Class Methods

+ (MSStatusStore *)sharedStore
{
    static MSStatusStore *sharedStore = nil;
    static dispatch_once_t storeToken;
    dispatch_once(&storeToken, ^{
        
        sharedStore = [[MSStatusStore alloc] init];
    });
    
    return sharedStore;
}


#pragma mark - Instance Methods

- (void)postStatusWithText:(NSString *)status inReplyToId:(NSString *)statusId withMedia:(NSArray *)media isSensitive:(BOOL)sensitive withVisibility:(NSString *)visibilityType andSpoilerText:(NSString *)spoilerText withProgress:(void (^)(CGFloat))progress withCompletion:(void (^)(BOOL, NSDictionary *, NSError *))completion
{
    self.progressBlock = progress;
    
    NSMutableDictionary *params = [@{} mutableCopy];
    
    if (!status || !status.length) {
        status = @"\u200B";
    }
    
    [params setObject:status forKey:@"status"];
    
    if (statusId) {
        [params setObject:statusId forKey:@"in_reply_to_id"];
    }
    
    if (sensitive) {
        [params setObject:@(YES) forKey:@"sensitive"];
    }
    
    if (visibilityType) {
        [params setObject:visibilityType forKey:@"visibility"];
    }
    
    if (spoilerText) {
        [params setObject:spoilerText forKey:@"spoiler_text"];
    }
    

    if (media) {
        
        __block NSString *__status = status;
        [self uploadMedia:media withCompletion:^(BOOL success, NSArray *mediaIds, NSArray *mediaUrls) {
            if (success) {
                [params setObject:mediaIds forKey:@"media_ids"];
                
                for (NSString *url in mediaUrls) {
                    if (status.length + url.length + 1 < 500) {
                        __status = [__status stringByAppendingFormat:@"\n%@", url];
                    }
                }
                
                [params setObject:__status forKey:@"status"];
                
                [self postStatusWithParameters:params withCompletion:completion];
            }
            else
            {
                self.progressBlock = nil;
                
                if (completion != nil) {
                    NSError *error = [NSError errorWithDomain:@"com.keyboardfloofs.DireFloof" code:500 userInfo:@{NSLocalizedFailureReasonErrorKey: @"Media upload failure"}];
                    
                    completion(NO, nil, error);
                }
            }
        }];
    }
    else
    {
        [self postStatusWithParameters:params withCompletion:completion];
    }

}


- (void)deleteStatusWithId:(NSString *)statusId withCompletion:(void (^)(BOOL, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"statuses/%@", statusId];
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] DELETE:requestUrl parameters:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if (completion != nil) {
            completion(YES, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        if (completion != nil) {
            completion(NO, error);
        }
    }];
}


- (void)reblogStatusWithId:(NSString *)statusId withCompletion:(void (^)(BOOL, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"statuses/%@/reblog", statusId];
    
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


- (void)unreblogStatusWithId:(NSString *)statusId withCompletion:(void (^)(BOOL, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"statuses/%@/unreblog", statusId];
    
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


- (void)favoriteStatusWithId:(NSString *)statusId withCompletion:(void (^)(BOOL, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"statuses/%@/favourite", statusId];
    
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


- (void)unfavoriteStatusWithId:(NSString *)statusId withCompletion:(void (^)(BOOL, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"statuses/%@/unfavourite", statusId];
    
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


- (void)reportStatus:(MSStatus *)status withComments:(NSString *)comments withCompletion:(void (^)(BOOL, NSError *))completion
{
    NSMutableDictionary *params = [@{} mutableCopy];
    
    if (!status.account._id || !status._id) {
        if (completion != nil) {
            NSError *noIdError = [NSError errorWithDomain:@"com.keyboardfloofs.DireFloof" code:500 userInfo:@{NSLocalizedFailureReasonErrorKey: @"No account or status id to report, please notify an admin."}];
            completion(NO, noIdError);
        }
    }
    [params setObject:status.account._id forKey:@"account_id"];
    [params setObject:@[status._id] forKey:@"status_ids"];
    
    if (!comments || !comments.length) {
        comments = @"\u200B";
    }
    
    if (comments.length) {
        [params setObject:comments forKey:@"comment"];
    }
    
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] POST:@"reports" parameters:params constructingBodyWithBlock:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (completion != nil) {
            completion(YES, nil);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (completion != nil) {
            completion(NO, error);
        }
    }];
}


- (void)muteStatusWithId:(NSString *)statusId withCompletion:(void (^)(BOOL, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"statuses/%@/mute", statusId];
    
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


- (void)unmuteStatusWithId:(NSString *)statusId withCompletion:(void (^)(BOOL, NSError *))completion
{
    NSString *requestUrl = [NSString stringWithFormat:@"statuses/%@/unmute", statusId];
    
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


#pragma mark - Private Methods

- (void)postStatusWithParameters:(NSDictionary *)params withCompletion:(void (^)(BOOL, NSDictionary *, NSError *))completion
{
    [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] POST:@"statuses" parameters:params constructingBodyWithBlock:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        self.progressBlock = nil;
        
        if (completion != nil) {
            completion(YES, responseObject, nil);
        }
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        self.progressBlock = nil;
        
        if (completion != nil) {
            completion(NO, nil, error);
        }
    }];
}


- (void)uploadMedia:(NSArray *)media withCompletion:(void (^)(BOOL success, NSArray *mediaIds, NSArray *mediaUrls))completion
{
    NSUInteger numberToUpload = media.count;
    __block NSUInteger numberUploaded = 0;
    __block NSUInteger numberFailed = 0;
    __block CGFloat totalProgress = 0.0f;
    
    NSMutableArray *mediaIds = [@[] mutableCopy];
    NSMutableArray *mediaUrls = [@[] mutableCopy];
    
    for (NSDictionary *mediaDict in media) {
        
        PHAsset *mediaObject = [mediaDict objectForKey:MS_MEDIA_ATTACHMENT_MEDIA_KEY];
        NSString *mediaDescription = [mediaDict objectForKey:MS_MEDIA_ATTACHMENT_DESCRIPTION_KEY];
        
        NSUInteger uploadIndex = [media indexOfObject:mediaDict];
        
        if (mediaObject.mediaType == PHAssetMediaTypeImage) {
            PHImageRequestOptions *options = [PHImageRequestOptions new];
            options.version = PHImageRequestOptionsVersionCurrent;
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            options.resizeMode = PHImageRequestOptionsResizeModeNone;
            
            [[PHImageManager defaultManager] requestImageDataForAsset:mediaObject options:options resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                
                totalProgress += 1.0f/(CGFloat)numberToUpload * 0.5f;
                
                if (self.progressBlock) {
                    self.progressBlock(totalProgress);
                }
                
                NSString *extension = @"";
                if ([info objectForKey:@"PHImageFileURLKey"]) {
                    NSURL *path = [info objectForKey:@"PHImageFileURLKey"];
                    extension = [path pathExtension];
                }
                
                NSString *filename = @"file";
                if (extension.length) {
                    filename = [filename stringByAppendingPathExtension:extension];
                }
                NSString *MIME = (__bridge NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)dataUTI, kUTTagClassMIMEType);
                
                [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] POST:@"media" parameters:@{@"description": mediaDescription} constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                    
                    [formData appendPartWithFileData:imageData name:@"file" fileName:filename mimeType:MIME];
                } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                    
                    totalProgress += 1.0f/(CGFloat)numberToUpload * 0.5f;
                    
                    if (self.progressBlock) {
                        self.progressBlock(totalProgress);
                    }
                    
                    numberUploaded += 1;
                    
                    if (mediaIds.count > uploadIndex) {
                        [mediaIds insertObject:[responseObject objectForKey:@"id"] atIndex:uploadIndex];
                        [mediaUrls insertObject:[responseObject objectForKey:@"text_url"] atIndex:uploadIndex];
                    }
                    else
                    {
                        [mediaIds addObject:[responseObject objectForKey:@"id"]];
                        [mediaUrls addObject:[responseObject objectForKey:@"text_url"]];
                    }
                    
                    if (numberUploaded + numberFailed >= numberToUpload) {
                        if (numberFailed > 0) {
                            if (completion != nil) {
                                completion(NO, nil, nil);
                            }
                        }
                        else
                        {
                            if (completion != nil) {
                                completion(YES, mediaIds, mediaUrls);
                            }
                        }
                    }
                } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                    
                    numberFailed += 1;
                    
                    if (numberUploaded + numberFailed >= numberToUpload) {
                        if (numberFailed > 0) {
                            if (completion != nil) {
                                completion(NO, nil, nil);
                            }
                        }
                        else
                        {
                            if (completion != nil) {
                                completion(YES, mediaIds, mediaUrls);
                            }
                        }
                    }
                }];
                
            }];
        }
        else
        {
        
            PHVideoRequestOptions *options = [PHVideoRequestOptions new];
            options.version = PHVideoRequestOptionsVersionCurrent;
            options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
            options.networkAccessAllowed = YES;
            options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                if (self.progressBlock) {
                    self.progressBlock(progress * (1.0f/3.0f));
                }
            };
            
            [[PHImageManager defaultManager] requestExportSessionForVideo:mediaObject options:options exportPreset:AVAssetExportPresetMediumQuality resultHandler:^(AVAssetExportSession * _Nullable exportSession, NSDictionary * _Nullable info) {
                
                exportSession.outputFileType = AVFileTypeMPEG4;
                exportSession.shouldOptimizeForNetworkUse = YES;
                exportSession.videoComposition = [self getVideoComposition:exportSession.asset];
                
                NSString *mediaIdentifier = [[[NSUUID UUID] UUIDString] stringByAppendingString:@".mp4"];
                
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
                NSString *cachePath = [paths objectAtIndex:0];
                BOOL isDir = NO;
                
                NSError *error;
                if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath isDirectory:&isDir]) {
                    [[NSFileManager defaultManager] createDirectoryAtPath:cachePath withIntermediateDirectories:NO attributes:nil error:&error];
                }
                
                NSString *filePath = [cachePath stringByAppendingPathComponent:mediaIdentifier];
                
                exportSession.outputURL = [NSURL fileURLWithPath:filePath];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    if (self.progressBlock) {
                        [self updateProgressOnExportSession:exportSession];
                    }
                });
                
                [exportSession exportAsynchronouslyWithCompletionHandler:^{
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        
                        totalProgress += 1.0f/(CGFloat)numberToUpload * 0.5f;
                        
                        [[MSAPIClient sharedClientWithBaseAPI:[[MSAppStore sharedStore] base_api_url_string]] POST:@"media" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                            
                            
                            [formData appendPartWithFileURL:[NSURL fileURLWithPath:filePath] name:@"file" fileName:@"file.mp4" mimeType:@"video/mp4" error:nil];
                            
                        } progress:^(NSProgress * _Nonnull uploadProgress) {
                            
                            if (self.progressBlock) {
                                self.progressBlock((2.0f/3.0f) + uploadProgress.fractionCompleted * (1.0f/3.0f));
                            }
                            
                        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                            
                            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                            
                            totalProgress += 1.0f/(CGFloat)numberToUpload * 0.5f;
                            
                            numberUploaded += 1;
                            [mediaIds addObject:[responseObject objectForKey:@"id"]];
                            [mediaUrls addObject:[responseObject objectForKey:@"text_url"]];
                            
                            if (numberUploaded + numberFailed >= numberToUpload) {
                                if (numberFailed > 0) {
                                    if (completion != nil) {
                                        completion(NO, nil, nil);
                                    }
                                }
                                else
                                {
                                    if (completion != nil) {
                                        completion(YES, mediaIds, mediaUrls);
                                    }
                                }
                            }
                        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                            
                            [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
                            
                            numberFailed += 1;
                            
                            if (numberUploaded + numberFailed >= numberToUpload) {
                                if (numberFailed > 0) {
                                    if (completion != nil) {
                                        completion(NO, nil, nil);
                                    }
                                }
                                else
                                {
                                    if (completion != nil) {
                                        completion(YES, mediaIds, mediaUrls);
                                    }
                                }
                            }
                        }];

                        
                    });
                }];
                
            }];
        }
    }
}


- (void)updateProgressOnExportSession:(AVAssetExportSession *)exportSession
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.progressBlock) {
            self.progressBlock((1.0f/3.0f) + exportSession.progress * (1.0f/3.0f));
        }
    });
    
    if (exportSession.progress < 1.0f) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            if (self.progressBlock) {
                [self updateProgressOnExportSession:exportSession];
            }
        });
    }
}


- (AVMutableVideoComposition *)getVideoComposition:(AVAsset *)asset
{
    AVAssetTrack *videoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    CGSize videoSize = videoTrack.naturalSize;
    BOOL isPortrait_ = [self isVideoPortrait:asset];
    if(isPortrait_) {
        //NSLog(@"video is portrait ");
        videoSize = CGSizeMake(videoSize.height, videoSize.width);
    }
    composition.naturalSize     = videoSize;
    videoComposition.renderSize = videoSize;
    // videoComposition.renderSize = videoTrack.naturalSize; //
    videoComposition.frameDuration = CMTimeMakeWithSeconds( 1 / videoTrack.nominalFrameRate, 600);
    
    AVMutableCompositionTrack *compositionVideoTrack;
    compositionVideoTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    [compositionVideoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration) ofTrack:videoTrack atTime:kCMTimeZero error:nil];
    AVMutableVideoCompositionLayerInstruction *layerInst;
    layerInst = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    [layerInst setTransform:videoTrack.preferredTransform atTime:kCMTimeZero];
    AVMutableVideoCompositionInstruction *inst = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    inst.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
    inst.layerInstructions = [NSArray arrayWithObject:layerInst];
    videoComposition.instructions = [NSArray arrayWithObject:inst];
    return videoComposition;
}


- (BOOL)isVideoPortrait:(AVAsset *)asset
{
    BOOL isPortrait = FALSE;
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks    count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        
        CGAffineTransform t = videoTrack.preferredTransform;
        // Portrait
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0)
        {
            isPortrait = YES;
        }
        // PortraitUpsideDown
        if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0)  {
            
            isPortrait = YES;
        }
        // LandscapeRight
        if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0)
        {
            isPortrait = FALSE;
        }
        // LandscapeLeft
        if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0)
        {
            isPortrait = FALSE;
        }
    }
    return isPortrait;
}

@end
