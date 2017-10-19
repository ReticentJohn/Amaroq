# OAuth2-for-iOS

It's a library on iOS which is suitable for OAuth2. It supports authorization all websites which are using OAuth2 such as: smarthings, uber, fitbit, delivery, etc...

[![Build Status](https://travis-ci.org/trongdth/OAuth2-for-iOS.svg?branch=master)](https://travis-ci.org/trongdth/OAuth2-for-iOS)
[![Version](https://img.shields.io/cocoapods/v/OAuth2.svg?style=flat)](http://cocoapods.org/pods/OAuth2)
[![License](https://img.shields.io/cocoapods/l/OAuth2.svg?style=flat)](http://cocoapods.org/pods/OAuth2)
[![Platform](https://img.shields.io/cocoapods/p/OAuth2.svg?style=flat)](http://cocoapods.org/pods/OAuth2)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

## OVERVIEW

1. https://github.com/lukeredpath/LROAuth2Client: I was developing based on this library. Basically, it covers > 80% the works. Please share and thanks him about this.
 
2. https://github.com/nicklockwood/Base64: it's base64 library I'm using for this library.

## IMPROVEMENTS

 1. UI:
   + Use autolayout.
   + Use ARC.
   + Make UX better.

 2. Authorization:
   + Add initWithDict function for OAuthRequestController 
   + Add Authorization key in order to avoid some website requires it.

 3. More things:
   + Fix warning and some small issues for LROAuth2Client
   + Upgrade lib to pod project for easy use.

## Usage

 1. To run the example project, clone the repo, and run `pod install` from the Example directory first.

 2. Declare OAuthRequestController:

```objective-c
NSMutableDictionary *dictService = [NSMutableDictionary dictionary];
[dictService setObject:@"https://www.fitbit.com/oauth2/authorize" forKey:kOAuth_AuthorizeURL];
[dictService setObject:@"https://api.fitbit.com/oauth2/token" forKey:kOAuth_TokenURL];
[dictService setObject:@"YOUR CLIENT ID" forKey:kOAuth_ClientId];
[dictService setObject:@"YOUR SECRET KEY" forKey:kOAuth_Secret];
[dictService setObject:@"YOUR CALLBACK URL" forKey:kOAuth_Callback];
[dictService setObject:@"activity heartrate location nutrition profile settings sleep social weight" forKey:kOAuth_Scope];


OAuthRequestController *oauthController = [[OAuthRequestController alloc] initWithDict:dictService];
oauthController.view.frame = self.view.frame;
oauthController.delegate = self;
[self presentViewController:oauthController animated:YES completion:^{

}];
```

 3. Implement OAuthRequestController method to obtain accesstoken:

```objective-c
- (void)didAuthorized:(NSDictionary *)dictResponse {
    NSLog(@"%@", dictResponse);
}
```



## Installation

1. Pod:
+ OAuth2 is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "OAuth2"
```

2. Carthage:
+ For Carthage installation:

```ruby
github "trongdth/OAuth2-for-iOS" "master"
```


## Author

Trong Dinh, trongdth@gmail.com

## License

OAuth2 is available under the MIT license. See the LICENSE file for more info.
