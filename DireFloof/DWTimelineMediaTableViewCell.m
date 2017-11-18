//
//  DWTimelineMediaTableViewCell.m
//  DireFloof
//
//  Created by John Gabelmann on 2/15/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <GPUImage/GPUImage.h>
#import <AVKit/AVKit.h>
#import <MHVideoPhotoGallery/MHGalleryController.h>
#import <PureLayout/PureLayout.h>
#import <CHTCollectionViewWaterfallLayout/CHTCollectionViewWaterfallLayout.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <UIKit/UIKit.h>
#import "DWTimelineMediaTableViewCell.h"
#import "DWMediaCollectionViewCell.h"
#import "DWIntrinsicCollectionView.h"
#import "UIApplication+TopController.h"
#import "DWMediaStore.h"
#import "DWConstants.h"
#import "DWSettingStore.h"

@interface DWTimelineMediaTableViewCell () <UICollectionViewDelegate, UICollectionViewDataSource, CHTCollectionViewDelegateWaterfallLayout>

@property (nonatomic, weak) IBOutlet DWIntrinsicCollectionView *collectionView;
@property (nonatomic, assign) BOOL hasBeenAwakened;

@end

@implementation DWTimelineMediaTableViewCell

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

#pragma mark - Initialization

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [(CHTCollectionViewWaterfallLayout *)self.collectionView.collectionViewLayout setColumnCount:1];
    [(CHTCollectionViewWaterfallLayout *)self.collectionView.collectionViewLayout setMinimumColumnSpacing:4.0f];
    [(CHTCollectionViewWaterfallLayout *)self.collectionView.collectionViewLayout setMinimumInteritemSpacing:4.0f];
    [(CHTCollectionViewWaterfallLayout *)self.collectionView.collectionViewLayout setSectionInset:UIEdgeInsetsZero];
    
    [[NSNotificationCenter defaultCenter] addObserver:self.collectionView selector:@selector(reloadData) name:DW_DID_PURGE_CACHE_NOTIFICATION object:nil];
}


- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.collectionView reloadData];
    [self.collectionView invalidateIntrinsicContentSize];
}


- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    
    // workaround to kick intrinsic sizing to work properly
    [self.collectionView layoutIfNeeded];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Getter/Setter Overrides

- (void)setStatus:(MSStatus *)status
{
    [super setStatus:status];
    
    if (self.status) {
        MSStatus *newStatus = self.status.reblog ? self.status.reblog : self.status;
        
        BOOL needsInvalidation = NO;
        if (newStatus.media_attachments.count > 1 && [(CHTCollectionViewWaterfallLayout *)self.collectionView.collectionViewLayout columnCount] == 1) {
            [(CHTCollectionViewWaterfallLayout *)self.collectionView.collectionViewLayout setColumnCount:2];
            needsInvalidation = YES;
        }
        else if (newStatus.media_attachments.count == 1 && [(CHTCollectionViewWaterfallLayout *)self.collectionView.collectionViewLayout columnCount] == 2)
        {
            [(CHTCollectionViewWaterfallLayout *)self.collectionView.collectionViewLayout setColumnCount:1];
            needsInvalidation = YES;
        }
        
        if (needsInvalidation) {
            [self.collectionView.collectionViewLayout invalidateLayout];
        }
        
        [self.collectionView reloadData];
        [self.collectionView invalidateIntrinsicContentSize];
    }

}


#pragma mark - UICollectionView Delegate Methods

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (self.status) {
        MSStatus *status = self.status.reblog ? self.status.reblog : self.status;
        
        return status.media_attachments.count;
    }
    
    return 1;
}


- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    MSStatus *status = self.status.reblog ? self.status.reblog : self.status;
    return status.media_attachments.count > 2 ? 4.0f : 0.0f;
}


- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    MSStatus *status = self.status.reblog ? self.status.reblog : self.status;

    return status.media_attachments.count > 1 ? 4.0f : 0.0f;
}


- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    MSStatus *status = self.status.reblog ? self.status.reblog : self.status;

    CGFloat collectionViewWidth = self.isThreadStatus ? [UIApplication sharedApplication].keyWindow.bounds.size.width - 20.0f : [UIApplication sharedApplication].keyWindow.bounds.size.width - 80.0f;
    CGFloat collectionViewHeight = self.isThreadStatus ? collectionViewWidth : collectionViewWidth/2.0f;
    
    CGSize mediaSize = CGSizeMake(collectionViewWidth, collectionViewHeight);
    
    if (status.media_attachments.count > 1) {
        mediaSize.width = mediaSize.width / 2.0f - 2;
    }
    
    if (status.media_attachments.count > 3 || (status.media_attachments.count > 2 && indexPath.row != 0)) {
        mediaSize.height = mediaSize.height / 2.0f - 2;
    }
    
    if (mediaSize.height < 0) {
        mediaSize.height = 0;
    }
    
    if (mediaSize.width < 0) {
        mediaSize.width = 0;
    }
    
    return mediaSize;
}


- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    DWMediaCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"MediaCell" forIndexPath:indexPath];
    
    [self configureMediaCell:cell atIndexPath:indexPath];
    
    return cell;
}


- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    MSStatus *status = self.status.reblog ? self.status.reblog : self.status;

    NSMutableArray *photos = [@[] mutableCopy];
    
    for (MSMediaAttachment *media in status.media_attachments) {
        
        NSString *mediaURL = media.url ? media.url : media.remote_url;
        
        if ((media.type != MSMediaTypeImage) && ![mediaURL containsString:@".mp4"]) {
            continue;
        }
        
        if (media.type != MSMediaTypeImage) {
            
            NSURL *cachedURL = [[DWMediaStore sharedStore] cachedURLForGifvMedia:[NSURL URLWithString:mediaURL]];
            
            if (cachedURL) {
                mediaURL = [cachedURL absoluteString];
            }
        }
        


        MHGalleryItem *photo = [MHGalleryItem itemWithURL:mediaURL galleryType:media.type == MSMediaTypeImage ? MHGalleryTypeImage : MHGalleryTypeVideo];
        [photos addObject:photo];
    }
    
    if (!photos.count) {
        return;
    }
    
    DWMediaCollectionViewCell *selectedCell = (DWMediaCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    
    MHGalleryController *browser = [MHGalleryController galleryWithPresentationStyle:MHGalleryViewModeImageViewerNavigationBarHidden];
    browser.galleryItems = photos;
    browser.presentationIndex = indexPath.row;
    browser.presentingFromImageView = selectedCell.mediaImageView;
    browser.autoplayVideos = YES;
    browser.preferredStatusBarStyleMH = UIStatusBarStyleLightContent;
    
    MHUICustomization *browserStyling = [[MHUICustomization alloc] init];
    browserStyling.barTintColor = DW_BAR_TINT_COLOR;
    browserStyling.barButtonsTintColor = DW_LINK_TINT_COLOR;
    browserStyling.videoProgressTintColor = DW_LINK_TINT_COLOR;
    browserStyling.showOverView = NO;
    [browserStyling setMHGalleryBackgroundColor:DW_BACKGROUND_COLOR forViewMode:MHGalleryViewModeImageViewerNavigationBarHidden];
    [browserStyling setMHGalleryBackgroundColor:DW_BACKGROUND_COLOR forViewMode:MHGalleryViewModeImageViewerNavigationBarShown];
    
    browser.UICustomization = browserStyling;
    
    __weak MHGalleryController *_browser = browser;
    
    browser.finishedCallback = ^(NSInteger currentIndex, UIImage *image, MHTransitionDismissMHGallery *interactiveTransition, MHGalleryViewMode viewMode) {
        
        DWMediaCollectionViewCell *returnCell = (DWMediaCollectionViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:currentIndex inSection:0]];
        
        
        [_browser dismissViewControllerAnimated:YES dismissImageView:returnCell.mediaImageView completion:nil];
    };
    
    [[[UIApplication sharedApplication] topController] presentMHGalleryController:browser animated:YES completion:nil];
}


#pragma mark - Private Methods

- (void)configureMediaCell:(DWMediaCollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    if (cell.gpuVideoImageView) {
        if (cell.gpuVideo) {
            [cell.gpuVideo removeTarget:cell.gpuVideoImageView];
            [cell.gpuVideo cancelProcessing];
        }
        
        [cell.gpuVideoImageView removeFromSuperview];
        cell.gpuVideoImageView = nil;
        cell.gpuVideo = nil;
    }
    
    if (!self.status) {
        return;
    }
    
    MSStatus *status = self.status.reblog ? self.status.reblog : self.status;

    MSMediaAttachment *media = [status.media_attachments objectAtIndex:indexPath.row];
    NSString *mediaUrl = media.url ? media.url : media.remote_url;
    cell.identifier = status._id;
    
    if (media.type != MSMediaTypeImage && [mediaUrl containsString:@"mp4"]) {
        
        if (media.type == MSMediaTypeGifv && ![[DWSettingStore sharedStore] disableGifPlayback] && status.media_attachments.count == 1 && !status.sensitive && !status.spoiler_text.length) {
            
            [[DWMediaStore sharedStore] downloadGifvMedia:[NSURL URLWithString:mediaUrl] withCompletion:^(BOOL success, NSURL *localURL, NSError *error) {
                if (success) {
                    
                    if ([cell.identifier isEqual:status._id]) {
                        
                        if (cell.gpuVideoImageView) {
                            if (cell.gpuVideo) {
                                [cell.gpuVideo removeTarget:cell.gpuVideoImageView];
                                [cell.gpuVideo cancelProcessing];
                            }
                            
                            [cell.gpuVideoImageView removeFromSuperview];
                            cell.gpuVideoImageView = nil;
                            cell.gpuVideo = nil;
                        }
                        
                        GPUImageView *gifVideoView = [[GPUImageView alloc] initWithFrame:cell.mediaImageView.frame];
                        gifVideoView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
                        gifVideoView.accessibilityLabel = media._description;
                        gifVideoView.isAccessibilityElement = media._description ? YES : NO;
                        
                        GPUImageMovie *gifVideo = [[GPUImageMovie alloc] initWithURL:localURL];
                        gifVideo.shouldRepeat = YES;
                        gifVideo.playAtActualSpeed = YES;
                        
                        [gifVideo addTarget:gifVideoView];
                        
                        [cell.contentView addSubview:gifVideoView];
                        [gifVideoView autoPinEdgesToSuperviewEdges];
                        
                        cell.gpuVideoImageView = gifVideoView;
                        cell.gpuVideo = gifVideo;
                        
                        [cell.gpuVideo startProcessing];
                        
                        [[NSNotificationCenter defaultCenter] addObserver:cell.gpuVideo selector:@selector(cancelProcessing) name:DW_WILL_PURGE_CACHE_NOTIFICATION object:nil];
                        [[NSNotificationCenter defaultCenter] addObserver:cell.gpuVideo selector:@selector(removeAllTargets) name:DW_WILL_PURGE_CACHE_NOTIFICATION object:nil];
                    }
                    
                }
                else
                {
                    //NSLog(@"Error: %@", error.localizedDescription);
                }
            }];
        }
        else
        {
            cell.playImageView.hidden = NO;
            [cell.contentView bringSubviewToFront:cell.mediaImageView];
            [cell.contentView bringSubviewToFront:cell.playImageView];
        }

    }
    else
    {
        [cell.contentView bringSubviewToFront:cell.mediaImageView];
        [cell.contentView bringSubviewToFront:cell.playImageView];
    }

    cell.mediaImageView.accessibilityLabel = media._description;
    cell.mediaImageView.isAccessibilityElement = media._description ? YES : NO;
    [cell.mediaImageView setImageWithURL:[NSURL URLWithString:media.preview_url ? media.preview_url : media.remote_url] placeholderImage:[[DWMediaStore sharedStore] placeholderImage]];
}

@end
