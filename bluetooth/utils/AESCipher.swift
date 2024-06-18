//
//  AESCipher.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/15.
//

import Foundation
import Foundation
import CryptoKit
import Foundation
import CryptoKit

struct AESCipher {
    static let keySize = SymmetricKeySize.bits256 // Use a 256-bit key for AES
    
    // Function to generate a random symmetric key
    static func generateKey() -> SymmetricKey {
        return SymmetricKey(size: keySize)
    }
    
    // Function to convert Data to a Hex string (for displaying the key)
    static func dataToHex(_ data: Data) -> String {
        return data.map { String(format: "%02hhx", $0) }.joined()
    }
    
    // Encrypt function
    static func encrypt(data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    // Decrypt function
    static func decrypt(data: Data, using key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
}

struct AESKeyExpander {
    static func expandKey(key: Data) -> [UInt32] {
        // AES key schedule (expansion) example for a 256-bit key
        let keyWords = key.withUnsafeBytes {
            $0.bindMemory(to: UInt32.self)
        }
        
        var expandedKey = [UInt32](repeating: 0, count: 60)
        for i in 0..<8 {
            expandedKey[i] = keyWords[i]
        }
        
        let rcon: [UInt32] = [
            0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36
        ]
        
        for i in 8..<60 {
            var temp = expandedKey[i - 1]
            if i % 8 == 0 {
                temp = subWord(rotWord(temp)) ^ rcon[(i / 8) - 1]
            } else if i % 8 == 4 {
                temp = subWord(temp)
            }
            expandedKey[i] = expandedKey[i - 8] ^ temp
        }
        return expandedKey
    }
    
    static func rotWord(_ word: UInt32) -> UInt32 {
        return (word << 8) | (word >> 24)
    }
    
    static func subWord(_ word: UInt32) -> UInt32 {
        // Substitute bytes (example for simplicity, in practice use a precomputed S-box)
        let sBox: [UInt8] = [
            0x63, 0x7c, 0x77, 0x7b, 0xf2, 0x6b, 0x6f, 0xc5, 0x30, 0x01, 0x67, 0x2b, 0xfe, 0xd7, 0xab, 0x76,
            // Rest of the S-box...
        ]
        
        var result: UInt32 = 0
        for i in 0..<4 {
            let byte = (word >> (8 * i)) & 0xFF
            result |= UInt32(sBox[Int(byte)]) << (8 * i)
        }
        return result
    }
    
    func test(){
        // Example usage:
        let message = "This is a secret message"
        let messageData = message.data(using: .utf8)!

        // Generate a random key
        let key = AESCipher.generateKey()
        let keyHex = AESCipher.dataToHex(key.withUnsafeBytes { Data(Array($0)) })
        print("Key: \(keyHex)")

        // Encrypt the message
        do {
            let encryptedData = try AESCipher.encrypt(data: messageData, using: key)
            print("Encrypted data: \(encryptedData.base64EncodedString())")

            // Decrypt the message
            let decryptedData = try AESCipher.decrypt(data: encryptedData, using: key)
            if let decryptedMessage = String(data: decryptedData, encoding: .utf8) {
                print("Decrypted message: \(decryptedMessage)")
            }
        } catch {
            print("Encryption/Decryption error: \(error)")
        }

        // Key expansion example
        let keyData = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
                            0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
                            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
                            0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F])
        let expandedKey = AESKeyExpander.expandKey(key: keyData)
        print("Expanded Key: \(expandedKey)")

    }
}

 
