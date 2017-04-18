//
//  DWAboutViewController.m
//  DireFloof
//
//  Created by John Gabelmann on 3/9/17.
//  Copyright © 2017 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "DWAboutViewController.h"
#import "NSString+Awoo.h"
#import "DWSettingStore.h"
#import "DWConstants.h"

@interface DWAboutViewController ()

@property (nonatomic, weak) IBOutlet UILabel *versionLabel;
@property (nonatomic, weak) IBOutlet UITextView *textView;
@property (nonatomic, weak) IBOutlet UIButton *switchButton;
@property (nonatomic, weak) IBOutlet UIWebView *webView;


@end

@implementation DWAboutViewController

#pragma mark - Actions

- (IBAction)closeButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)switchButtonPressed:(UIButton *)sender
{
    sender.selected = !sender.selected;
    [self configureViews];
}


#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configureViews) name:UIContentSizeCategoryDidChangeNotification object:nil];
    
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *buildVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    
    self.versionLabel.text = [NSString stringWithFormat:@"v%@ (%@)", appVersion, buildVersion];
    
    NSString *textToDisplay = NSLocalizedString(@"Amaroq is named after an Inuit legend of a giant wolf, which is fitting as a companion to our friend the mastodon. May we all howl across the fediverse!\n\nAmaroq is built and maintained by a love of the Mastodon idea, which sorely has needed a mobile outlet for our iOS friends. Got a suggestion, found a bug, or just want to voice some support? You can reach us at amaroq.feedback@gmail.com. Or hit up the dev, @eurasierboy on the mastodon.social instance. Happy tooting!", @"Amaroq is named after an Inuit legend of a giant wolf, which is fitting as a companion to our friend the mastodon. May we all howl across the fediverse!\n\nAmaroq is built and maintained by a love of the Mastodon idea, which sorely has needed a mobile outlet for our iOS friends. Got a suggestion, found a bug, or just want to voice some support? You can reach us at amaroq.feedback@gmail.com. Or hit up the dev, @eurasierboy on the mastodon.social instance. Happy tooting!");
    
    if ([[DWSettingStore sharedStore] awooMode]) {
        textToDisplay = [textToDisplay awooString];
    }
    
    self.textView.text = textToDisplay;
    
    self.webView.backgroundColor = [UIColor clearColor];
    self.webView.scrollView.backgroundColor = [UIColor clearColor];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[[NSBundle mainBundle] URLForResource:@"PrivacyPolicy" withExtension:@"html"]];
    [self.webView loadRequest:request];
    
    self.switchButton.selected = self.jumpToPrivacy;
    [self configureViews];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - Private Methods

- (void)configureViews
{
    self.webView.hidden = !self.switchButton.selected;
    self.textView.hidden = self.switchButton.selected;
    
    self.textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.switchButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    self.versionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
}

@end
