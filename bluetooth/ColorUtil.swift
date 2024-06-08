//
//  ColorUtil.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/8.
//

import Foundation
import SwiftUI
class ColorUtil{
    
    //颜色转rbg分量
    static func toRGBUInt8(color:Color) -> (red: UInt8, green: UInt8, blue: UInt8) {
        let components =  color.cgColor?.components
        let red = components?[0] ?? 0
        let green = components?[1] ?? 0
        let blue = components?[2] ?? 0
        return (
            red: UInt8(red * 255),
            green: UInt8(green * 255),
            blue: UInt8(blue * 255)
        )
        
    }
    
    
 
    /// 颜色数据转荧光棒字节数组
    /// - Parameters:
    ///   - red: red
    ///   - green: green
    ///   - blue: blue
    ///   - isEnabled: 是否点亮
    ///   - isSpeedEnabled: 是否闪烁
    ///   - speed: 闪烁速度
    /// - Returns: 字节数组
    static func buildColorData(red: UInt8,  green:UInt8,    blue:UInt8, isEnabled: Bool=true,
                               isSpeedEnabled: Bool=true, speed: Double) -> Data {
        // Convert hex color string to RGB
        // let rgb = hexToRGB(hex: hex)
        
        // Set the "enabled" and "speed" flags
        let enabledFlag: UInt8 = isEnabled ? UInt8(bitPattern: -1) : 0
        let speedFlag: UInt8 = isSpeedEnabled ? UInt8(bitPattern: -1) : 0
        
        // Calculate the speed value
        let speedValue: UInt8 = UInt8(((255 - (255 - (pow(16 - Double(speed), 2) - 1))) * pow(2, 24)).truncatingRemainder(dividingBy: 256))
        //let speedValue = UInt8(((255 - pow(16 - speed, 2) + 1)).truncatingRemainder(dividingBy: 256))
        // Create an 8-byte array to hold the command data
        var commandData = Data(count: 8)
        
        // Set the fixed command header
        commandData[0] = 0xAA
        commandData[1] = 0xA1
        
        // Set the RGB values
        commandData[2] = red
        commandData[3] =  green
        commandData[4] = blue
        
        // Set the "enabled" and "speed" flags
        commandData[5] = enabledFlag
        commandData[6] = speedFlag
        
        // Set the calculated speed value
        commandData[7] = speedValue
        
        // Return the prepared Data
        return commandData
    }
    
    static func hexToRGB(hex: String) -> (red: UInt8, green: UInt8, blue: UInt8) {
        var hexString = hex
        if hexString.hasPrefix("#") {
            hexString.remove(at: hexString.startIndex)
        }
        
        let scanner = Scanner(string: hexString)
        var hexNumber: UInt64 = 0
        if scanner.scanHexInt64(&hexNumber) {
            let red = UInt8((hexNumber & 0xFF0000) >> 16)
            let green = UInt8((hexNumber & 0x00FF00) >> 8)
            let blue = UInt8(hexNumber & 0x0000FF)
            return (red, green, blue)
        }
        
        return (0, 0, 0) // Default to black if the hex string is invalid
    }
    
    
    
    
  
}

