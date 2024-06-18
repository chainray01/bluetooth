//
//  PointerDecoder.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/15.
//

import Foundation
import Foundation

struct PointerDecoder {
    // Example XOR key for decoding; this should match the logic from the assembly code
    static let xorKey: UInt64 = 0xDEADBEEFDEADBEEF

    // Function to read and decode a pointer from a Data object
    static func readEncodedPointer(from data: Data, at offset: Int) -> UInt64? {
        // Ensure the offset is within bounds of the data
        guard offset + MemoryLayout<UInt64>.size <= data.count else {
            print("Offset out of bounds")
            return nil
        }
        
        // Read the 8-byte pointer value from the data
        let pointerRange = offset..<(offset + MemoryLayout<UInt64>.size)
        let encodedPointerData = data.subdata(in: pointerRange)
        
        // Convert the data to a UInt64 value
        let encodedPointer = encodedPointerData.withUnsafeBytes { $0.load(as: UInt64.self) }
        
        // Decode the pointer using an XOR operation
        let decodedPointer = encodedPointer ^ xorKey
        
        return decodedPointer
    }
    
    func test(){
        // Example usage:
        let data = Data([0x12, 0x34, 0x56, 0x78, 0x9A, 0xBC, 0xDE, 0xF0,
                         0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF])
        let offset = 8

        if let decodedPointer = PointerDecoder.readEncodedPointer(from: data, at: offset) {
            print(String(format: "Decoded Pointer: 0x%016llX", decodedPointer))
        } else {
            print("Failed to read encoded pointer")
        }

    }
}

