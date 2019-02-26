//
//  MSPushNotificationStore.swift
//  DireFloof
//
//  Created by John Gabelmann on 2/24/19.
//  Copyright © 2019 Keyboard Floofs. All rights reserved.
//
/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class MSPushNotificationStore: NSObject {

    static let singleton = MSPushNotificationStore()
    
    @objc class func sharedStore() -> MSPushNotificationStore {
        return MSPushNotificationStore.singleton
    }
    
    private var state: PushNotificationState? = UserDefaults(suiteName: "group.keyboardfloofs.amarok")?.retrieve(object: PushNotificationState.self, fromKey: MS_CLIENT_NOTIFICATION_STATE_KEY) {
        didSet {
            guard let state = state else {
                return
            }
            
            UserDefaults(suiteName: "group.keyboardfloofs.amarok")?.save(customObject: state, inKey: MS_CLIENT_NOTIFICATION_STATE_KEY)
        }
    }
    
    @objc func subscribePushNotifications(_ deviceToken: NSData, completion: ((Bool, NSError?) -> Void)?) {
        
        let token = (deviceToken as Data).map { String(format: "%02.2hhx", $0) }.joined()
        let requestToken = PushNotificationDeviceToken(deviceToken: deviceToken as Data)
        
        // TODO: Think of a better way to only update the notification state on token change, this will have notification decryption problems on network failure
        let alerts = PushNotificationAlerts(favourite: DWSettingStore.shared()?.favoriteNotifications ?? false, follow: DWSettingStore.shared()?.newFollowerNotifications ?? false, mention: DWSettingStore.shared()?.mentionNotifications ?? false, reblog: DWSettingStore.shared()?.boostNotifications ?? false)
        let subscription = PushNotificationSubscription(endpoint: URL(string:"https://amaroq-apns.herokuapp.com/relay-to/production/\(token)")!, alerts: alerts)
        let receiver = try! PushNotificationReceiver()
        state = PushNotificationState(receiver: receiver, subscription: subscription, deviceToken: requestToken)
        
        let params = PushNotificationSubscriptionRequest(endpoint: "https://amaroq-apns.herokuapp.com/relay-to/production/\(token)", receiver: receiver, alerts: alerts)
        
        guard let baseAPI = MSAppStore.shared()?.base_api_url_string else {
            if let completion = completion {
                completion(false, nil)
            }
            return
        }
                
        MSAPIClient.sharedClient(withBaseAPI: baseAPI)?.post("push/subscription", parameters: params.dictionary, constructingBodyWith: nil, progress: nil, success: { (task, responseObject) in
            
            if let completion = completion {
                completion(true, nil)
            }
        }, failure: { (task, error) in
            if let completion = completion {
                completion(false, error as NSError)
            }
        })
    }
}


extension UserDefaults {
    
    func save<T:Encodable>(customObject object: T, inKey key: String) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(object) {
            self.set(encoded, forKey: key)
        }
    }
    
    func retrieve<T:Decodable>(object type:T.Type, fromKey key: String) -> T? {
        if let data = self.data(forKey: key) {
            let decoder = JSONDecoder()
            if let object = try? decoder.decode(type, from: data) {
                return object
            }else {
                print("Couldnt decode object")
                return nil
            }
        }else {
            print("Couldnt find key")
            return nil
        }
    }
    
}

extension Encodable {
    var dictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}
