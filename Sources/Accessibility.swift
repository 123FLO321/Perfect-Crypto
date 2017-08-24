//
//  Accessibility.swift
//  PerfectCrypto
//
//  Created by Jonathan Guthrie on 2017-08-23.
//

import Foundation

/// Provides a wrapper around the PerfectCrypto functions that give easy encryption/decryption with deterministic salts.
extension String {

	public func encrypt(password: String, _ cipher: Cipher = .aes_256_cbc) throws -> String {
		if self.isEmpty {
			throw CryptoError(code: Int(98), msg: "No data to encrypt")
		}
		if password.isEmpty {
			throw CryptoError(code: Int(99), msg: "Password cannot be empty")
		}

		// String -> to bytes/UINT8
		let bytes = uint8Array()

		// The key value for the encrypt/decrypt
		// pad password/key to key length
		do {
			let key = try keygen(password, cipher.keyLength)
			// Initialization vector
			let iv = [UInt8](randomCount: cipher.ivLength)
			
			// encrypt, then base64 encode response string
			var encrypted: [UInt8] = iv
			for i in bytes.encrypt(cipher, key: key, iv: iv) ?? [UInt8]() {
				encrypted.append(i)
			}
			
			let hexBytes = encrypted.encode(.base64)
			return String(validatingUTF8: hexBytes ?? [UInt8]()) ?? ""
		} catch {
			throw error
		}
	}

	public func decrypt(password: String, _ cipher: Cipher = .aes_256_cbc) throws -> String {
		if password.isEmpty {
			throw CryptoError(code: Int(99), msg: "Password cannot be empty")
		}

		let d1 = uint8Array()
		let data = d1.decode(.base64) ?? [UInt8]()

		// key, padded to correct length
		do {
			let key = try keygen(password, cipher.keyLength)
			// initialization vector. taken from first x ofencrypted data
			var iv = [UInt8]()
			for i in 0..<(cipher.keyLength - 1) {
				iv.append(data[i])
			}
			// now remove
			let x = data.dropFirst(cipher.ivLength)

			// make sure it's a [Uint8], not what is generated by drop
			var encrypted = [UInt8]()
			for i in x { encrypted.append(i) }
			// decrypt
			let decrypted = encrypted.decrypt(cipher, key: key, iv: iv)
			//return
			return String(validatingUTF8: decrypted ?? [UInt8]()) ?? ""
		} catch {
			throw error
		}

	}

	private func uint8Array() -> [UInt8] {
		let r: [UInt8] = Array(self.utf8)
		return r
	}

	private func keygen(_ key: String, _ length: Int) throws -> [UInt8] {
		if key.isEmpty {
			throw CryptoError(code: Int(99), msg: "Key cannot be empty")
		}
		var tkey = key
		let base64key = {
			() -> String in
			while tkey.lengthOfBytes(using: String.Encoding.utf8) < length {
				tkey = tkey.toBase64()
			}
			return tkey
		}
		let encodedBytes = base64key().uint8Array()
		var b = [UInt8]()
		for i in 0..<(encodedBytes.count - 1) {
			b.append(encodedBytes[i])
		}
		if b.count > length {
			b.removeLast(length - b.count)
		}
		return b
	}

	private func toBase64() -> String {
		return Data(self.utf8).base64EncodedString()
	}

}

