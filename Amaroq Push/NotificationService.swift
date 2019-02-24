//
//  NotificationService.swift
//  Amaroq Push
//
//  Created by John Gabelmann on 2/24/19.
//  Copyright © 2019 Keyboard Floofs. All rights reserved.
//

import UserNotifications

let MS_CLIENT_NOTIFICATION_STATE_KEY = "MS_CLIENT_NOTIFICATION_STATE_KEY"

class NotificationService: UNNotificationServiceExtension {
    

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
        
            guard let notificationState = UserDefaults(suiteName: "group.keyboardfloofs.amarok")?.retrieve(object: PushNotificationState.self, fromKey: MS_CLIENT_NOTIFICATION_STATE_KEY), let content = try? bestAttemptContent.decrypt(state: notificationState) else {
                contentHandler(bestAttemptContent)
                return
            }
            
            // Modify the notification content here...
            bestAttemptContent.title = content.title
            bestAttemptContent.body = content.body
            bestAttemptContent.badge = 1
            bestAttemptContent.sound = UNNotificationSound.default
            
            if let strippedTitle = (content.title as NSString).removeHTML() {
                bestAttemptContent.title = strippedTitle
            }
            
            if let strippedBody = (content.body as NSString).removeHTML() {
                bestAttemptContent.body = strippedBody
            }
            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
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
