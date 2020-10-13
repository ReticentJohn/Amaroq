//
//  MSAuthStore.swift
//  DireFloof
//
//  Created by John Gabelmann on 6/1/20.
//  Copyright © 2020 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import p2_OAuth2
import WebKit

class MSOAuthStore: NSObject {

    static let singleton = MSOAuthStore()
    
    private var oauth2: OAuth2CodeGrant?
    
    @objc class func sharedStore() -> MSOAuthStore {
        return MSOAuthStore.singleton
    }
    @objc func authorize(settings: [String: AnyObject], completion: ((Bool, NSError?) -> Void)?) {
        oauth2 = OAuth2CodeGrant(settings: settings)
        
        oauth2?.authConfig.authorizeEmbedded = true
        oauth2?.authConfig.ui.useAuthenticationSession = true
        oauth2?.authConfig.authorizeContext = UIApplication.shared.keyWindow
        oauth2?.authorize { (response, error) in
            
            if let accessToken = self.oauth2?.accessToken {
                MSAuthStore.shared()?.credential = AFOAuthCredential(oAuthToken: accessToken, tokenType: "Bearer")
                AFOAuthCredential.store(MSAuthStore.shared()!.credential, withIdentifier: MSAppStore.shared()!.base_api_url_string)
                
                if let completion = completion {
                    completion(true, nil)
                }
            } else if let completion = completion {
                completion(false, nil)
            }
        }
    }
}
