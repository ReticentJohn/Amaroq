//
//  DWComposeViewController.m
//  DireFloof
//
//  Created by John Gabelmann on 2/23/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <RMPickerViewController/RMPickerViewController.h>
#import <twitter-text/TwitterText.h>
#import <YLProgressBar/YLProgressBar.h>
#import <GMImagePicker/GMImagePickerController.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import "DWComposeViewController.h"
#import "DWConstants.h"
#import "DWSettingStore.h"

typedef NS_ENUM(NSUInteger, DWPrivacyType) {
    DWPrivacyTypeDirect        = 0,
    DWPrivacyTypePrivate,
    DWPrivacyTypeUnlisted,
    DWPrivacyTypePublic,
};

@interface DWComposeViewController () <UITextViewDelegate, UITextFieldDelegate, GMImagePickerControllerDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, weak) IBOutlet UIImageView *avatarImageView;
@property (nonatomic, weak) IBOutlet UILabel *usernameLabel;
@property (nonatomic, weak) IBOutlet UITextField *contentWarningField;
@property (nonatomic, weak) IBOutlet UITextView *contentField;
@property (nonatomic, weak) IBOutlet UILabel *contentLengthLabel;
@property (nonatomic, weak) IBOutlet UIButton *tootButton;
@property (nonatomic, weak) IBOutlet UISwitch *contentWarningSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *sensitiveMediaSwitch;

@property (nonatomic, weak) IBOutlet UILabel *contentFieldPlaceholderLabel;

@property (nonatomic, weak) IBOutlet UIImageView *image1;
@property (nonatomic, weak) IBOutlet UIImageView *image2;
@property (nonatomic, weak) IBOutlet UIImageView *image3;
@property (nonatomic, weak) IBOutlet UIImageView *image4;

@property (nonatomic, weak) IBOutlet YLProgressBar *progressBar;

@property (nonatomic, weak) IBOutlet UIView *replyToView;
@property (nonatomic, weak) IBOutlet UIView *crossInstanceWarningView;
@property (nonatomic, weak) IBOutlet UIImageView *replyToAvatarImageView;
@property (nonatomic, weak) IBOutlet UILabel *replyToDisplayNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *replyToUsernameLabel;
@property (nonatomic, weak) IBOutlet UILabel *replyToContentLabel;

@property (nonatomic, weak) IBOutlet UILabel *hideTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *sensitiveContentLabel;
@property (nonatomic, weak) IBOutlet UILabel *reportingLabel;
@property (nonatomic, weak) IBOutlet UILabel *warningLabel;

@property (nonatomic, weak) IBOutlet UIButton *privacyButton;

@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *statusUploadingIndicator;

@property (nonatomic, strong) NSMutableArray *imagesToUpload;

@property (nonatomic, assign) BOOL videoSelected;
@property (nonatomic, strong) NSString *privacyState;
@property (nonatomic, strong) NSArray *privacyOptions;

@end

@implementation DWComposeViewController

#pragma mark - Constants

static NSInteger contentLengthLimit = 500;
static NSInteger mediaUploadLimit = 4;

#pragma mark - Actions

- (IBAction)contentSwitchChanged:(UISwitch *)sender
{
    [self.view endEditing:YES];
    
    [self reloadFields];
}


- (IBAction)tootButtonPressed:(id)sender
{
    [self.view endEditing:YES];
    
    NSInteger charactersRemaining = contentLengthLimit - self.contentField.text.length - (self.contentWarningSwitch.on ? self.contentWarningField.text.length : 0);
    
    if (charactersRemaining < 0) {
        return;
    }
    
    self.tootButton.enabled = NO;
    self.progressBar.hidden = NO;
    [self.statusUploadingIndicator startAnimating];
    
    [[MSStatusStore sharedStore] postStatusWithText:self.contentField.text inReplyToId:self.replyToStatus ? self.replyToStatus._id : nil withMedia:(self.imagesToUpload.count ? self.imagesToUpload : nil) isSensitive:(self.sensitiveMediaSwitch.on && !self.sensitiveMediaSwitch.superview.hidden) withVisibility:self.privacyState andSpoilerText:(self.contentWarningSwitch.on ? self.contentWarningField.text : nil) withProgress:^(CGFloat progress) {
    
        [self.progressBar setProgress:progress animated:YES];
        
    } withCompletion:^(BOOL success, NSDictionary *status, NSError *error) {
        
        self.tootButton.enabled = YES;
        [self.statusUploadingIndicator stopAnimating];
        
        if (success) {
            
            [self.progressBar setProgress:1.0f animated:YES];

            
            if (self.postCompleteBlock) {
                self.postCompleteBlock(YES);
            }
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            self.progressBar.hidden = YES;
            
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Failed to post status with error:", @"Failed to post status with error:"), error.localizedFailureReason] preferredStyle:UIAlertControllerStyleAlert];
            
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
            
            [self presentViewController:alertController animated:YES completion:nil];
        }
        
    }];
}


- (IBAction)reportSubmitButtonPressed:(id)sender
{
    [self.view endEditing:YES];
    
    self.tootButton.enabled = NO;
    [self.statusUploadingIndicator startAnimating];

    [[MSStatusStore sharedStore] reportStatus:self.replyToStatus withComments:self.contentField.text withCompletion:^(BOOL success, NSError *error) {
        self.tootButton.enabled = YES;
        [self.statusUploadingIndicator stopAnimating];

        if (success) {
            
            if (self.postCompleteBlock) {
                self.postCompleteBlock(YES);
            }
            
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", @"Error") message:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Failed to report status with error:", @"Failed to report status with error:"), error.localizedFailureReason] preferredStyle:UIAlertControllerStyleAlert];
            
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }];
}


- (IBAction)cancelButtonPressed:(id)sender
{
    if (self.postCompleteBlock) {
        self.postCompleteBlock(NO);
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)imageButtonSelected:(id)sender
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    
    if (status == PHAuthorizationStatusDenied) {
        return;
    }
    
    if (status == PHAuthorizationStatusNotDetermined) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self presentImagePicker];
                });
            }
        }];
    }
    
    if (status == PHAuthorizationStatusAuthorized || status == PHAuthorizationStatusRestricted) {
        [self presentImagePicker];
    }

}


- (IBAction)deleteImageButtonPressed:(UIButton *)sender
{
    [self.imagesToUpload removeObjectAtIndex:sender.tag];
    [self reloadFields];
}


- (IBAction)privacyButtonPressed:(id)sender
{
    [self.view endEditing:YES];
    
    RMAction<UIPickerView *> *selectAction = [RMAction<UIPickerView *> actionWithTitle:NSLocalizedString(@"Done", @"Done") style:RMActionStyleDone andHandler:^(RMActionController<UIPickerView *> * _Nonnull controller) {
        
        NSUInteger selectedRow = [controller.contentView selectedRowInComponent:0];
        
        switch (selectedRow) {
            case DWPrivacyTypeDirect:
                self.privacyState = MS_VISIBILITY_TYPE_DIRECT;
                break;
            case DWPrivacyTypePrivate:
                self.privacyState = MS_VISIBILITY_TYPE_PRIVATE;
                break;
            case DWPrivacyTypeUnlisted:
                self.privacyState = MS_VISIBILITY_TYPE_UNLISTED;
                break;
            case DWPrivacyTypePublic:
                self.privacyState = MS_VISIBILITY_TYPE_PUBLIC;
                break;
            default:
                break;
        }
        
        [self reloadFields];

    }];
    
    RMAction<UIPickerView *> *cancelAction = [RMAction<UIPickerView *> actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:RMActionStyleCancel andHandler:^(RMActionController<UIPickerView *> * _Nonnull controller) {
        
    }];
    
    RMPickerViewController *pickerController = [RMPickerViewController actionControllerWithStyle:RMActionControllerStyleDefault selectAction:selectAction andCancelAction:cancelAction];
    pickerController.title = NSLocalizedString(@"Select a privacy level", @"Select a privacy level");
    pickerController.message = [NSString stringWithFormat:@"\n%@\n\n%@\n\n%@\n\n%@", NSLocalizedString(@"Direct: Only visible to you and @mentioned users", @"Direct: Only visible to you and @mentioned users"), NSLocalizedString(@"Followers-only: Only visible to you, @mentioned users, and your followers", @"Followers-only: Only visible to you, @mentioned users, and your followers"), NSLocalizedString(@"Unlisted: Visible to everyone, but not shown on local or federated timelines", @"Unlisted: Visible to everyone, but not shown on local or federated timelines"), NSLocalizedString(@"Public: Visible to everyone on local and federated timelines", @"Public: Visible to everyone on local and federated timelines")];
    pickerController.disableBlurEffects = YES;
    pickerController.picker.dataSource = self;
    pickerController.picker.delegate = self;
    
    NSUInteger selectedRow = DWPrivacyTypePublic;
    
    if ([self.privacyState isEqualToString:MS_VISIBILITY_TYPE_DIRECT]) {
        selectedRow = DWPrivacyTypeDirect;
    }
    else if ([self.privacyState isEqualToString:MS_VISIBILITY_TYPE_PRIVATE])
    {
        selectedRow = DWPrivacyTypePrivate;
    }
    else if ([self.privacyState isEqualToString:MS_VISIBILITY_TYPE_UNLISTED])
    {
        selectedRow = DWPrivacyTypeUnlisted;
    }
    
    [pickerController.picker selectRow:selectedRow inComponent:0 animated:NO];
    
    [self presentViewController:pickerController animated:YES completion:nil];
}


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.imagesToUpload = [@[] mutableCopy];
    self.privacyOptions = @[NSLocalizedString(@"Direct", @"Direct"),
                            NSLocalizedString(@"Followers-only", @"Followers-only"),
                            NSLocalizedString(@"Unlisted", @"Unlisted"),
                            NSLocalizedString(@"Public", @"Public")];
    [self configureViews];
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


- (BOOL)shouldAutorotate
{
    return NO;
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - UITextView Delegate Methods

- (void)textViewDidChange:(UITextView *)textView
{
    self.contentFieldPlaceholderLabel.hidden = textView.text.length;
    
    NSInteger charactersRemaining = contentLengthLimit - textView.text.length - (self.contentWarningSwitch.on ? self.contentWarningField.text.length : 0);
    
    self.contentLengthLabel.text = [NSString stringWithFormat:@"%li", (long)charactersRemaining];
    
    if (([self.privacyState isEqualToString:MS_VISIBILITY_TYPE_PRIVATE] || [self.privacyState isEqualToString:MS_VISIBILITY_TYPE_DIRECT])) {
        NSArray *entities = [textView.text componentsSeparatedByString:@" "];
        
        BOOL matches = [[entities filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF LIKE[cd] %@", @"@?*@?*.?*"]] count];
        
        if (self.crossInstanceWarningView.hidden == matches) {
            [UIView animateWithDuration:0.2f animations:^{
                self.crossInstanceWarningView.hidden = !matches;
            }];
        }
    }
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSInteger charactersRemaining = contentLengthLimit - self.contentField.text.length - (self.contentWarningSwitch.on ? [[textField.text stringByReplacingCharactersInRange:range withString:string] length] : 0);
    
    self.contentLengthLabel.text = [NSString stringWithFormat:@"%li", (long)charactersRemaining];
    
    return YES;
}


#pragma mark - GMImagePickerController Delegate Methods

- (void)assetsPickerController:(GMImagePickerController *)picker didFinishPickingAssets:(NSArray *)assets
{
    [self.imagesToUpload addObjectsFromArray:assets];
    [self reloadFields];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (BOOL)assetsPickerController:(GMImagePickerController *)picker shouldSelectAsset:(PHAsset *)asset
{
    if (asset.mediaType == PHAssetMediaTypeVideo && (self.imagesToUpload.count > 0 || picker.selectedAssets.count > 0)) {
        return NO;
    }

    if (picker.selectedAssets.count + self.imagesToUpload.count >= 4) {
        return NO;
    }
    
    if (asset.mediaType == PHAssetMediaTypeImage) {
        
        for (PHAsset *selectedAsset in picker.selectedAssets) {
            
            if (selectedAsset.mediaType == PHAssetMediaTypeVideo) {
                return NO;
            }
        }
    }
    else if (asset.duration > 31.0f)
    {

        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Video too long", @"Video too long") message:NSLocalizedString(@"Please keep to videos up to 30 seconds long", @"Please keep to videos up to 30 seconds long") preferredStyle:UIAlertControllerStyleAlert];
        
        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
        
        [picker presentViewController:alertController animated:YES completion:nil];
        
        return NO;
    }
    
    return YES;
}


#pragma mark - UIPickerView Delegate Methods

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}


- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return self.privacyOptions.count;
}


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [self.privacyOptions objectAtIndex:row];
}


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    
}


#pragma mark - Private Methods

- (void)configureViews
{
    MSAccount *currentUser = [[MSUserStore sharedStore] currentUser];

    if (!self.reporting) {
        [self.avatarImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[[DWSettingStore sharedStore] disableGifPlayback] ? currentUser.avatar_static : currentUser.avatar]] placeholderImage:nil success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
            self.avatarImageView.image = image;
            if ([[DWSettingStore sharedStore] disableGifPlayback]) {
                [self.avatarImageView stopAnimating];
            }
        } failure:nil];

        self.usernameLabel.text = [[MSAppStore sharedStore] instance];
    }
    else
    {
        self.usernameLabel.text = self.replyToStatus.account.username;
    }
    
    self.contentField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.privacyButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.contentLengthLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.tootButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.usernameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.reportingLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.hideTextLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.sensitiveContentLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.contentFieldPlaceholderLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.replyToContentLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    self.replyToUsernameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.replyToDisplayNameLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    self.warningLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.contentWarningField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    
    self.privacyButton.titleLabel.numberOfLines = 0;
    self.contentWarningField.text = @"";
    self.contentField.text = @"";
    self.contentLengthLabel.text = [NSString stringWithFormat:@"%li", (long)contentLengthLimit];
    self.contentFieldPlaceholderLabel.hidden = NO;
    self.contentWarningSwitch.on = NO;
    self.sensitiveMediaSwitch.on = NO;
    
    if ([[DWSettingStore sharedStore] alwaysPrivate]) {
        self.privacyState = MS_VISIBILITY_TYPE_PRIVATE;
    }
    else if (![[DWSettingStore sharedStore] alwaysPublic])
    {
        self.privacyState = MS_VISIBILITY_TYPE_UNLISTED;
    }
    else
    {
        self.privacyState = MS_VISIBILITY_TYPE_PUBLIC;
    }
    
    if (currentUser.locked) {
        self.privacyState = MS_VISIBILITY_TYPE_PRIVATE;
    }
    
    self.image1.superview.hidden = YES;
    self.image2.superview.hidden = YES;
    self.image3.superview.hidden = YES;
    self.image4.superview.hidden = YES;
    
    self.progressBar.hidden = YES;
    
    if ([[DWSettingStore sharedStore] awooMode] && !self.reporting) {
        [self.tootButton setTitle:@"AWOO" forState:UIControlStateNormal];
        [self.tootButton setTitle:@"AWOO!" forState:UIControlStateSelected];
    }
    
    if (self.replyToStatus) {
        
        if ([self.replyToStatus.visibility isEqualToString:MS_VISIBILITY_TYPE_DIRECT]) {
            
            self.privacyState = MS_VISIBILITY_TYPE_DIRECT;
            self.privacyButton.userInteractionEnabled = NO;
        }
        
        if (self.replyToStatus.spoiler_text.length) {
            self.contentWarningField.text = self.replyToStatus.spoiler_text;
            self.contentWarningSwitch.on = YES;
        }
        
        self.replyToContentLabel.text = self.replyToStatus.content;
        self.replyToUsernameLabel.text = [NSString stringWithFormat:@"@%@", self.replyToStatus.account.acct];
        self.replyToDisplayNameLabel.text = self.replyToStatus.account.display_name.length ? self.replyToStatus.account.display_name : self.replyToStatus.account.username;
        
        [self.replyToAvatarImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[[DWSettingStore sharedStore] disableGifPlayback] ? self.replyToStatus.account.avatar_static : self.replyToStatus.account.avatar]] placeholderImage:nil success:^(NSURLRequest * _Nonnull request, NSHTTPURLResponse * _Nullable response, UIImage * _Nonnull image) {
            self.replyToAvatarImageView.image = image;
            if ([[DWSettingStore sharedStore] disableGifPlayback]) {
                [self.replyToAvatarImageView stopAnimating];
            }
        } failure:nil];
        
        //[self.replyToAvatarImageView setImageWithURL:[NSURL URLWithString:[[DWSettingStore sharedStore] disableGifPlayback] ? self.replyToStatus.account.avatar_static : self.replyToStatus.account.avatar]];
        
        NSString *replyToText = [self.replyToStatus.account.acct isEqualToString:[[MSUserStore sharedStore] currentAccountString]] ? @"" : [NSString stringWithFormat:@"@%@ ", self.replyToStatus.account.acct];
                
        for (MSMention *entity in self.replyToStatus.mentions) {
            
            NSString *username = entity.acct;
            
            if (![replyToText containsString:username] && ![entity.acct isEqualToString:[[MSUserStore sharedStore] currentAccountString]]) {
                replyToText = [replyToText stringByAppendingFormat:@"@%@ ", username];
            }
        }
        
        self.contentField.text = self.reporting ? @"" : replyToText;
        self.contentFieldPlaceholderLabel.hidden = YES;
    }
    else if (self.mentionedUser)
    {
        self.replyToView.hidden = YES;
        self.contentFieldPlaceholderLabel.hidden = YES;
        self.contentField.text = [NSString stringWithFormat:@"%@%@ ", [[self.mentionedUser substringToIndex:1] isEqualToString:@"@"] ? @"" : @"@", self.mentionedUser];
    }
    else
    {
        self.replyToView.hidden = YES;
    }
    
    [self.contentField becomeFirstResponder];
    
    [self reloadFields];
}


- (void)reloadFields
{
    [self.view endEditing:YES];
    
    self.contentWarningField.superview.hidden = !self.contentWarningSwitch.on;    
    self.sensitiveMediaSwitch.superview.hidden = !self.imagesToUpload.count;
    
    if ((![self.privacyState isEqualToString:MS_VISIBILITY_TYPE_PRIVATE] && ![self.privacyState isEqualToString:MS_VISIBILITY_TYPE_DIRECT]) && !self.crossInstanceWarningView.hidden) {
        self.crossInstanceWarningView.hidden = YES;
    }
    
    [self textViewDidChange:self.contentField];
    
    NSString *privacyString = nil;
    
    if ([self.privacyState isEqualToString:MS_VISIBILITY_TYPE_DIRECT]) {
        privacyString = NSLocalizedString(@"Direct", @"Direct");
    }
    else if ([self.privacyState isEqualToString:MS_VISIBILITY_TYPE_PRIVATE])
    {
        privacyString = NSLocalizedString(@"Private", @"Private");
    }
    else if ([self.privacyState isEqualToString:MS_VISIBILITY_TYPE_UNLISTED])
    {
        privacyString = NSLocalizedString(@"Unlisted", @"Unlisted");
    }
    else
    {
        privacyString = NSLocalizedString(@"Public", @"Public");
    }
    
    [self.privacyButton setTitle:privacyString forState:UIControlStateNormal];
    
    if ([self.privacyState isEqualToString:MS_VISIBILITY_TYPE_DIRECT] || [self.privacyState isEqualToString:MS_VISIBILITY_TYPE_PRIVATE]) {
        [self.tootButton setImage:[UIImage imageNamed:@"PrivateIconSmall"] forState:UIControlStateNormal];
    }
    else
    {
        [self.tootButton setImage:nil forState:UIControlStateNormal];
    }
    
    self.tootButton.selected = [self.privacyState isEqualToString:MS_VISIBILITY_TYPE_PUBLIC];
    [self.tootButton invalidateIntrinsicContentSize];
    
    self.videoSelected = NO;
    for (PHAsset *selectedAsset in self.imagesToUpload) {
        
        if (selectedAsset.mediaType == PHAssetMediaTypeVideo) {
            self.videoSelected = YES;
        }
    }
    
    self.image1.image = nil;
    self.image2.image = nil;
    self.image3.image = nil;
    self.image4.image = nil;
    
    switch (self.imagesToUpload.count) {
        case 1:
            self.image1.superview.hidden = NO;
            self.image2.superview.hidden = YES;
            self.image3.superview.hidden = YES;
            self.image4.superview.hidden = YES;
            [self loadImageAssetForImageView:self.image1 AtIndex:0];
            break;
        case 2:
            self.image1.superview.hidden = NO;
            self.image2.superview.hidden = NO;
            self.image3.superview.hidden = YES;
            self.image4.superview.hidden = YES;
            [self loadImageAssetForImageView:self.image1 AtIndex:0];
            [self loadImageAssetForImageView:self.image2 AtIndex:1];
            break;
        case 3:
            self.image1.superview.hidden = NO;
            self.image2.superview.hidden = NO;
            self.image3.superview.hidden = NO;
            self.image4.superview.hidden = YES;
            [self loadImageAssetForImageView:self.image1 AtIndex:0];
            [self loadImageAssetForImageView:self.image2 AtIndex:1];
            [self loadImageAssetForImageView:self.image3 AtIndex:2];
            break;
        case 4:
            self.image1.superview.hidden = NO;
            self.image2.superview.hidden = NO;
            self.image3.superview.hidden = NO;
            self.image4.superview.hidden = NO;
            [self loadImageAssetForImageView:self.image1 AtIndex:0];
            [self loadImageAssetForImageView:self.image2 AtIndex:1];
            [self loadImageAssetForImageView:self.image3 AtIndex:2];
            [self loadImageAssetForImageView:self.image4 AtIndex:3];
            break;
        default:
            self.image1.superview.hidden = YES;
            self.image2.superview.hidden = YES;
            self.image3.superview.hidden = YES;
            self.image4.superview.hidden = YES;
            break;
    }
}


- (void)loadImageAssetForImageView:(UIImageView *)imageView AtIndex:(NSUInteger)index
{
    PHAsset *asset = [self.imagesToUpload objectAtIndex:index];
    
    PHImageRequestOptions *options = [PHImageRequestOptions new];
    options.version = PHImageRequestOptionsVersionCurrent;
    options.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:imageView.bounds.size contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
        
        [imageView setImage:result];
    }];
}


- (void)presentImagePicker
{
    [self.view endEditing:YES];
    
    NSInteger imageLimitRemaining = mediaUploadLimit - self.imagesToUpload.count;
    
    if (imageLimitRemaining < 0) {
        return;
    }
    
    GMImagePickerController *picker = [[GMImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsMultipleSelection = YES;
    picker.showCameraButton = YES;
    picker.autoSelectCameraImages = YES;
    picker.displaySelectionInfoToolbar = YES;
    picker.mediaTypes = @[@(PHAssetMediaTypeImage), @(PHAssetMediaTypeVideo)];
    picker.pickerBackgroundColor = DW_BACKGROUND_COLOR;
    picker.pickerTextColor = DW_LINK_TINT_COLOR;
    picker.toolbarBarTintColor = DW_BAR_TINT_COLOR;
    picker.toolbarTextColor = DW_LINK_TINT_COLOR;
    picker.toolbarTintColor = DW_LINK_TINT_COLOR;
    picker.navigationBarBarTintColor = DW_BAR_TINT_COLOR;
    picker.navigationBarTextColor = [UIColor whiteColor];
    picker.navigationBarTintColor = DW_LINK_TINT_COLOR;
    picker.pickerFontName = @"Roboto-Regular";
    picker.pickerBoldFontName = @"Roboto-Medium";
    picker.pickerFontNormalSize = 15.0f;
    picker.pickerFontHeaderSize = 17.0f;
    picker.useCustomFontForNavigationBar = YES;
    
    picker.title = [NSString stringWithFormat:@"%@ %li %@%@", NSLocalizedString(@"Select", @"Select"), (long)imageLimitRemaining, imageLimitRemaining == 1 ? NSLocalizedString(@"image", @"image") : NSLocalizedString(@"images", @"images"), imageLimitRemaining == 4 ? NSLocalizedString(@" or 1 video", @" or 1 video") : @""];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Back", @"Back") style:UIBarButtonItemStylePlain target:nil action:nil];
    picker.navigationController.navigationBar.topItem.backBarButtonItem = backButton;
    
    [self presentViewController:picker animated:YES completion:nil];
}

@end
