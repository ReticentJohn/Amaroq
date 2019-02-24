import Foundation

public struct PushNotification: Codable, Equatable {
	public let accessToken: String
	public let preferredLocale: String
	public let notificationId: Int64
	public let notificationType: Type
	public let icon: URL
	public let title: String
	public let body: String

	enum CodingKeys: String, CodingKey {
		case accessToken = "access_token"
		case preferredLocale = "preferred_locale"
		case notificationId = "notification_id"
		case notificationType = "notification_type"
		case icon = "icon"
		case title = "title"
		case body = "body"
	}

	public enum `Type`: String, Codable, Equatable {
		case favourite = "favourite"
		case follow = "follow"
		case mention = "mention"
		case reblog = "reblog"
	}
}

public struct PushNotificationSubscription: Codable, Equatable {
	public let endpoint: URL
	public let alerts: PushNotificationAlerts

	public init(
		endpoint: URL,
		alerts: PushNotificationAlerts
	) {
		self.endpoint = endpoint
		self.alerts = alerts
	}
}

public struct PushNotificationAlerts: Codable, Equatable {
	public let favourite: Bool
	public let follow: Bool
	public let mention: Bool
	public let reblog: Bool

	public static var all = PushNotificationAlerts(favourite: true, follow: true, mention: true, reblog: true)

	public init(
		favourite: Bool,
		follow: Bool,
		mention: Bool,
		reblog: Bool
	) {
		self.favourite = favourite
		self.follow = follow
		self.mention = mention
		self.reblog = reblog
	}

	public var isActive: Bool {
		return favourite || follow || mention || reblog
	}
}

public struct PushNotificationSubscriptionRequest: Codable, Equatable {
	public let subscription: Subscription?
	public let data: Data

	public init(
		subscription: Subscription?,
		data: Data
	) {
		self.subscription = subscription
		self.data = data
	}

	public struct Subscription: Codable, Equatable {
		public let endpoint: String
		public let keys: Keys

		public init(
			endpoint: String,
			keys: Keys
		) {
			self.endpoint = endpoint
			self.keys = keys
		}

		public struct Keys: Codable, Equatable {
			public let p256dh: String
			public let auth: String

			public init(
				p256dh: String,
				auth: String
			) {
				self.p256dh = p256dh
				self.auth = auth
			}
		}
	}

	public struct Data: Codable, Equatable {
		public let alerts: PushNotificationAlerts

		public init(alerts: PushNotificationAlerts) {
			self.alerts = alerts
		}
	}
}

extension PushNotificationSubscriptionRequest {
	public init(endpoint: String, receiver: PushNotificationReceiver, alerts: PushNotificationAlerts) {
		self.init(
			subscription: .init(
				endpoint: endpoint,
				keys: .init(
					p256dh: receiver.publicKeyData.base64UrlEncodedString(),
					auth: receiver.authentication.base64UrlEncodedString()
				)
			), data: .init(alerts: alerts)
		)
	}
}

extension Data {
	func base64UrlEncodedString() -> String {
		return base64EncodedString()
			.replacingOccurrences(of: "+", with: "-")
			.replacingOccurrences(of: "/", with: "_")
			.replacingOccurrences(of: "=", with: "")
	}
}

public struct PushNotificationDeviceToken: Codable, Equatable {
	public let deviceToken: Data
	public let isProduction: Bool

	public init(deviceToken: Data) {
		self.deviceToken = deviceToken

		let startData = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>".data(using: .ascii)!
		let endData = "</plist>".data(using: .ascii)!

		if let url = Bundle.main.url(forResource: "embedded", withExtension: "mobileprovision"),
 		let data = try? Data(contentsOf: url),
 		let startIndex = data.range(of: startData)?.lowerBound,
		let endIndex = data.range(of: endData)?.upperBound,
		let plist = try? PropertyListSerialization.propertyList(from: data[startIndex ..< endIndex], options: [], format: nil),
 		let dict = plist as? [String: Any],
 		let entitlements = dict["Entitlements"] as? [String: Any],
		entitlements["aps-environment"] as? String == "development" {
			self.isProduction = false
 		} else {
			self.isProduction = true
    	}
	}

	public func endpoint(service: URL, extra: String?) -> URL {
		var endpoint = service
		endpoint.appendPathComponent(isProduction ? "production" : "development")
		endpoint.appendPathComponent(deviceToken.hexString)
		if let extra = extra {
			endpoint.appendPathComponent(extra)
		}
		return endpoint
	}
}

extension Data {
	var hexString: String {
	 	return map { String(format: "%02x", $0) }.joined()
	}

	func range(of substring: Data) -> Range<Int>? {
		for i in 0 ..< count - substring.count {
			var match = true
			for j in 0 ..< substring.count {
				if self[i + j] != substring[j] {
					match = false
					break
				}
			}
			if match {
				return i ..< i + substring.count
			}
		}
		return nil
	}
}

public struct PushNotificationState: Codable, Equatable {
	public let receiver: PushNotificationReceiver
	public let subscription: PushNotificationSubscription
	public let deviceToken: PushNotificationDeviceToken

	public init(
		receiver: PushNotificationReceiver,
		subscription: PushNotificationSubscription,
		deviceToken: PushNotificationDeviceToken
	) {
		self.receiver = receiver
		self.subscription = subscription
		self.deviceToken = deviceToken
	}
}

extension PushNotificationState {
	public func with(subscription: PushNotificationSubscription) -> PushNotificationState {
		return .init(
			receiver: receiver,
			subscription: subscription,
			deviceToken: deviceToken
		)
	}

	public func with(alerts: PushNotificationAlerts) -> PushNotificationState {
		return .init(
			receiver: receiver,
			subscription: .init(
				endpoint: subscription.endpoint,
				alerts: alerts
			),
			deviceToken: deviceToken
		)
	}
}

