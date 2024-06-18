//
//  DataHandler.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/15.
//

import Foundation
import Foundation
import CryptoKit

struct DataHandler {
    static func setEncryptShowData(data: Data, using key: SymmetricKey) -> Data? {
        do {
            // Encrypt the data
            let encryptedData = try AESCipher.encrypt(data: data, using: key)
            // Show the encrypted data (printing in this case)
            print("Encrypted data: \(encryptedData.base64EncodedString())")
            return encryptedData
        } catch {
            print("Encryption error: \(error)")
            return nil
        }
    }
    func test(){
        // Example usage
        let key = AESCipher.generateKey()
        let data = "Sample data to encrypt".data(using: .utf8)!
        if let encryptedData = DataHandler.setEncryptShowData(data: data, using: key) {
            print("Encrypted Data (Hex): \(AESCipher.dataToHex(encryptedData))")
        }

    }
}

