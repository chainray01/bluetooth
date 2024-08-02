//
//  ColorUtil.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/8.
//

import AVFoundation
import Accelerate
import Combine
import CoreBluetooth
import SwiftUI

struct ColorUtil {
    
    //颜色转rbg分量
    static func toRGBUInt8(color: Color) -> (red: UInt8, green: UInt8, blue: UInt8) {
        let components = color.cgColor?.components
        let red = components?[0] ?? 0
        let green = components?[1] ?? 0
        let blue = components?[2] ?? 0
        return (UInt8(red * 255), UInt8(green * 255), UInt8(blue * 255))
    }
    
    /// 颜色数据转荧光棒字节数组
    /// - Parameters:
    ///   - red: red
    ///   - green: green
    ///   - blue: blue
    ///   - isEnabled: 是否点亮
    ///   - isSpeedEnabled: 是否闪烁
    ///   - speed: 闪烁速度
    /// - Returns: [170, 161, 0, 146, 189, 255, 255, 20]
    static func buildColorData(
        _ red: UInt8, _ green: UInt8, _ blue: UInt8, _ isEnabled: Bool = true,
        _ isSpeedEnabled: Bool = false, _ speed: Double ) -> Data {
        
        // Set the "enabled" and "speed" flags true255 /false0
        let enabledFlag: UInt8 = isEnabled ? 255 : 0
        let speedFlag: UInt8 = isSpeedEnabled ? 255 : 0
        
        // Set the calculated speed value
        let realSpeed = UInt8(Constants.maxSpeed - speed)
        // Return the prepared Data
        
        let commandData = ColorCommand(r: red, g: green, b: blue, enabledFlag: enabledFlag, speedFlag: speedFlag, speed: realSpeed)!.toData()
        return commandData
    }
    
    static func argbToColor(argb: String) -> Color {
        // Clean the string and convert to uppercase
           var cleanedArgbString = argb.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
           
           // Remove the prefix #
           if cleanedArgbString.hasPrefix("#") {
               cleanedArgbString.remove(at: cleanedArgbString.startIndex)
           }
           
           // Add default alpha value if not present
           if cleanedArgbString.count == 6 {
               cleanedArgbString = "FF" + cleanedArgbString
           }
           
           // Convert the string to a number
           var argbValue: UInt64 = 0
           Scanner(string: cleanedArgbString).scanHexInt64(&argbValue)
           
           // Parse color components
           let alpha = CGFloat((argbValue & 0xFF00_0000) >> 24) / 255.0
           let red = CGFloat((argbValue & 0x00FF_0000) >> 16) / 255.0
           let green = CGFloat((argbValue & 0x0000_FF00) >> 8) / 255.0
           let blue = CGFloat(argbValue & 0x0000_00FF) / 255.0
           
           return Color(cgColor:.init(srgbRed: red, green: green, blue: blue, alpha: alpha))
    }
    
    /// 构建灯光数据
    /// - Parameters:
    ///   - color: 颜色
    ///   - isEnabled: 是否启用
    ///   - isSpeedEnabled: 启用速度
    ///   - speed: 速度
    /// - Returns: data
    static func buildColor(c color: Color,  isEnabled: Bool = true, isSpeedEnabled: Bool = false,   speed: Double) -> Data {
            let data = toRGBUInt8(color: color)
            return buildColorData(data.red, data.green, data.blue, isEnabled, isSpeedEnabled, speed)
        }
    
    static func buildTurnOff() -> Data {
        return buildColor(c: ColorUtil.argbToColor(argb: "#FF0092BD"),isEnabled: false,isSpeedEnabled: true,speed: 1)
    }
    
}
