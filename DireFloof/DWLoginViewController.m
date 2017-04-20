//
//  DWLoginViewController.m
//  DireFloof
//
//  Created by John Gabelmann on 2/14/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "DWLoginViewController.h"
#import "Mastodon.h"
#import "DWAboutViewController.h"
#import "DWConstants.h"

@interface DWLoginViewController () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *instanceField;
@property (nonatomic, weak) IBOutlet UITextField *placeholderField;
@property (nonatomic, weak) IBOutlet UIButton *loginButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView *loginActivityIndicator;
@property (nonatomic, weak) IBOutlet UILabel *subheaderLabel;
@property (nonatomic, weak) IBOutlet UIButton *privacyPolicyLabel;

@end

@implementation DWLoginViewController

#pragma mark - Actions

- (IBAction)loginButtonPressed:(id)sender
{
    [self.view endEditing:YES];
    [self.loginActivityIndicator startAnimating];
    self.loginButton.hidden = YES;
    
    [[MSAppStore sharedStore] setMastodonInstance:self.instanceField.text];
    
    [[MSAuthStore sharedStore] login:^(BOOL success) {
        
        self.loginButton.hidden = NO;
        
        [self.loginActivityIndicator stopAnimating];

        if (success) {
            if (self.addAccount) {
                // Notify the app to clear all its contents for refresh
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            else
            {
                [self performSegueWithIdentifier:@"LoginSegue" sender:self];
            }
        }
        else
        {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Login request failed", @"Login request failed") message:NSLocalizedString(@"Unable to connect to the Mastodon instance. Please try again later or with a different instance.", @"Unable to connect to the Mastodon instance. Please try again later or with a different instance.") preferredStyle:UIAlertControllerStyleAlert];
            
            [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK") style:UIAlertActionStyleCancel handler:nil]];
            
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }];
}


#pragma mark - Observers

- (void)cancelLogin
{
    self.loginButton.hidden = NO;
    
    [self.loginActivityIndicator stopAnimating];
}


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.instanceField.text = [[MSAppStore sharedStore] instance];
    
    self.placeholderField.hidden = self.instanceField.text.length;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(adjustFonts) name:UIContentSizeCategoryDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cancelLogin) name:DW_DID_CANCEL_LOGIN_NOTIFICATION object:nil];
    
    [self adjustFonts];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([[MSAuthStore sharedStore] isLoggedIn]) {
        [self performSegueWithIdentifier:@"LoginSegue" sender:self];
    }
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}


- (BOOL)shouldAutorotate
{
    if (!UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation])) {
        return YES;
    }
    
    return NO;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
    if ([segue.identifier isEqualToString:@"PrivacySegue"]) {
        DWAboutViewController *destinationViewController = segue.destinationViewController;
        destinationViewController.jumpToPrivacy = YES;
    }
}



#pragma mark - UITextField Delegate Methods

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.placeholderField.hidden = NO;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self loginButtonPressed:textField];
    
    return YES;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    self.placeholderField.hidden = [[textField.text stringByReplacingCharactersInRange:range withString:string] length];
    return YES;
}


#pragma mark - Private Methods

- (void)adjustFonts
{
    self.instanceField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.placeholderField.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.loginButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    self.privacyPolicyLabel.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    self.subheaderLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
}

@end
