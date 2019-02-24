import Foundation
import Security

public struct PushNotificationReceiver: Codable, Equatable, Hashable {
	public let privateKeyData: Data
	public let publicKeyData: Data
	public let authentication: Data
}

extension PushNotificationReceiver {
	public init() throws {
		var error: Unmanaged<CFError>?

		guard let privateKey = SecKeyCreateRandomKey([
			kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
			kSecAttrKeySizeInBits as String: 256,
		] as CFDictionary, &error) else {
			throw PushNotificationReceiverErrorType.creatingKeyFailed(error?.takeRetainedValue())
		}

		guard let privateKeyData = SecKeyCopyExternalRepresentation(privateKey, &error) as Data? else {
			throw PushNotificationReceiverErrorType.extractingPrivateKeyFailed(error?.takeRetainedValue())
		}

		guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
			throw PushNotificationReceiverErrorType.impossible
		}

		guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) as Data? else {
			throw PushNotificationReceiverErrorType.extractingPublicKeyFailed(error?.takeRetainedValue())
		}

		var authentication = Data(count: 16)
		try authentication.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) -> Void in
			guard SecRandomCopyBytes(kSecRandomDefault, 16, bytes) == errSecSuccess else {
				throw PushNotificationReceiverErrorType.creatingRandomDataFailed(error?.takeRetainedValue())
			}
		}

		self.init(
			privateKeyData: privateKeyData,
			publicKeyData: publicKeyData,
			authentication: authentication
		)
	}
}

extension PushNotificationReceiver {
	func decrypt(payload: Data, salt: Data, serverPublicKeyData: Data) throws -> Data {
		var error: Unmanaged<CFError>?

		guard let privateKey = SecKeyCreateWithData(privateKeyData as CFData,[
			kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
			kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
			kSecAttrKeySizeInBits as String: 256,
		] as CFDictionary, &error) else {
			throw PushNotificationReceiverErrorType.restoringKeyFailed(error?.takeRetainedValue())
		}

		guard let serverPublicKey = SecKeyCreateWithData(serverPublicKeyData as CFData,[
			kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
			kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
			kSecAttrKeySizeInBits as String: 256,
		] as CFDictionary, &error) else {
			throw PushNotificationReceiverErrorType.creatingKeyFailed(error?.takeRetainedValue())
		}

		guard let sharedSecret = SecKeyCopyKeyExchangeResult(privateKey, .ecdhKeyExchangeStandard, serverPublicKey, [:] as CFDictionary, &error) as Data? else {
			throw PushNotificationReceiverErrorType.keyExhangedFailed(error?.takeRetainedValue())
		}

		// TODO: These steps are slightly different from aes128gcm
		let secondSaltInfo = "Content-Encoding: auth\0".data(using: .utf8)!
		let secondSalt = deriveKey(firstSalt: authentication, secondSalt: sharedSecret, info: secondSaltInfo, length: 32)

		let keyInfo = info(type: "aesgcm", clientPublicKey: publicKeyData, serverPublicKey: serverPublicKeyData)
		let key = deriveKey(firstSalt: salt, secondSalt: secondSalt, info: keyInfo, length: 16)

		let nonceInfo = info(type: "nonce", clientPublicKey: publicKeyData, serverPublicKey: serverPublicKeyData)
		let nonce = deriveKey(firstSalt: salt, secondSalt: secondSalt, info: nonceInfo, length: 12)

		let gcm = try SwiftGCM(key: key, nonce: nonce, tagSize: 16)
		let clearText = try gcm.decrypt(auth: nil, ciphertext: payload)

		guard clearText.count >= 2 else {
			throw PushNotificationReceiverErrorType.clearTextTooShort
		}

		let paddingLength = Int(clearText[0]) * 256 + Int(clearText[1])
		guard clearText.count >= 2 + paddingLength else {
			throw PushNotificationReceiverErrorType.clearTextTooShort
		}

		let unpadded = clearText.suffix(from: paddingLength + 2)

		return unpadded
	}

	private func deriveKey(firstSalt: Data, secondSalt: Data, info: Data, length: Int) -> Data {
		return firstSalt.withUnsafeBytes { (firstSaltBytes: UnsafePointer<UInt8>) -> Data in
			return secondSalt.withUnsafeBytes { (secondSaltBytes: UnsafePointer<UInt8>) -> Data in
				return info.withUnsafeBytes { (infoBytes: UnsafePointer<UInt8>) -> Data in
					// RFC5869 Extract
					var context = CCHmacContext()
					CCHmacInit(&context, CCHmacAlgorithm(kCCHmacAlgSHA256), firstSaltBytes, firstSalt.count)
					CCHmacUpdate(&context, secondSaltBytes, secondSalt.count)

					var hmac: [UInt8] = .init(repeating: 0, count: 32)
					CCHmacFinal(&context, &hmac)

					// RFC5869 Expand
					CCHmacInit(&context, CCHmacAlgorithm(kCCHmacAlgSHA256), &hmac, hmac.count)
					CCHmacUpdate(&context, infoBytes, info.count)

					var one: [UInt8] = [1] // Add sequence byte. We only support short keys so this is always just 1.
					CCHmacUpdate(&context, &one, 1)
					CCHmacFinal(&context, &hmac)

					return Data(bytes: hmac.prefix(upTo: length))
				}
			}
		}
	}

	private func info(type: String, clientPublicKey: Data, serverPublicKey: Data) -> Data {
		var info = Data()

		info.append("Content-Encoding: ".data(using: .utf8)!)
		info.append(type.data(using: .utf8)!)
		info.append(0)
		info.append("P-256".data(using: .utf8)!)
		info.append(0)
		info.append(0)
		info.append(65)
		info.append(clientPublicKey)
		info.append(0)
		info.append(65)
		info.append(serverPublicKey)

		return info
	}
}

enum PushNotificationReceiverErrorType: Error {
	case invalidKey
	case impossible
	case creatingKeyFailed(Error?)
	case restoringKeyFailed(Error?)
	case extractingPrivateKeyFailed(Error?)
	case extractingPublicKeyFailed(Error?)
	case creatingRandomDataFailed(Error?)
	case keyExhangedFailed(Error?)
	case clearTextTooShort
}
