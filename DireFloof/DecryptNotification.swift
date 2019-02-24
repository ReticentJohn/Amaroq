import UserNotifications

extension UNNotificationContent {
	public func decrypt(state: PushNotificationState) throws -> PushNotification {
		// TODO: aes128gcm only uses p and x.
		guard let payload = (userInfo["p"] as? String)?.decode85(),
		let salt = (userInfo["s"] as? String)?.decode85(),
		let serverPublicKeyData = (userInfo["k"] as? String)?.decode85() else {
			throw DecryptNotificationErrorType.fieldsNotFound
		}

		let decrypted = try state.receiver.decrypt(payload: payload, salt: salt, serverPublicKeyData: serverPublicKeyData)

		return try JSONDecoder().decode(PushNotification.self, from: decrypted)
	}

/*	func decrypt(instanceRootSettings: SettingsStorage<AnyStringKey>) throws -> PushNotification {
		return try decrypt(settings: settings(instanceRootSettings: instanceRootSettings))
	}

	func decrypt(settings: SettingsStorage<InstanceKeys>) throws -> PushNotification {
		// TODO: aes128gcm only uses p and x.
		guard let payload = (userInfo["p"] as? String)?.decode85(),
		let salt = (userInfo["s"] as? String)?.decode85(),
		let serverPublicKeyData = (userInfo["k"] as? String)?.decode85() else {
			throw DecryptNotificationErrorType.fieldsNotFound
		}

		guard let state = settings.object(forKey: .pushNotificationState) as PushNotificationState? else {
			throw DecryptNotificationErrorType.subscriptionNotFound
		}

		let decrypted = try state.receiver.decrypt(payload: payload, salt: salt, serverPublicKeyData: serverPublicKeyData)

		return try JSONDecoder.mastodonDecoder.decode(PushNotification.self, from: decrypted)
	}

	func settings(instanceRootSettings: SettingsStorage<AnyStringKey>) throws -> SettingsStorage<InstanceKeys> {
		guard let identifier = userInfo["x"] as? String else {
			throw DecryptNotificationErrorType.fieldsNotFound
		}
		return instanceRootSettings.subSettings(forKey: AnyStringKey(identifier), keyedBy: InstanceKeys.self)
	}*/

	public func extraField() throws -> String {
		guard let extraField = userInfo["x"] as? String else {
			throw DecryptNotificationErrorType.fieldsNotFound
		}
		return extraField
	}
}

enum DecryptNotificationErrorType: String, Error {
	case fieldsNotFound
}

