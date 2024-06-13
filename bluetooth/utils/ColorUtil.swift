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
                               isSpeedEnabled: Bool=false, speed: Double) -> Data {
        // Convert hex color string to RGB
        // let rgb = hexToRGB(hex: hex)
        
        // Set the "enabled" and "speed" flags
        let enabledFlag: UInt8 = isEnabled ? UInt8(bitPattern: -1) : 0
        let speedFlag: UInt8 = isSpeedEnabled ? UInt8(bitPattern: -1) : 0
        
        // Calculate the speed value
        let result = pow(16 - speed, 2) - 1
        let speedValue: UInt8 = UInt8(result) & 0xFF

        
       // let speedValue: UInt8 = UInt8(pow(Double(16 - speed), 2) - 1) & 0xFF
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
    
    static func argbToColor(argb: String) -> Color {
                // 清理字符串并转换为大写
               var cleanedArgbString = argb.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
               // 移除前缀 #
               if cleanedArgbString.hasPrefix("#") {
                   cleanedArgbString.remove(at: cleanedArgbString.startIndex)
               }
               // 将字符串转换为数字
               var argbValue: UInt64 = 0
               Scanner(string: cleanedArgbString).scanHexInt64(&argbValue)
               
               // 解析颜色分量
               let alpha = CGFloat((argbValue & 0xFF000000) >> 24) / 255.0
               let red = CGFloat((argbValue & 0x00FF0000) >> 16) / 255.0
               let green = CGFloat((argbValue & 0x0000FF00) >> 8) / 255.0
               let blue = CGFloat(argbValue & 0x000000FF) / 255.0
            return Color(cgColor: .init(srgbRed: red, green: green, blue: blue, alpha: alpha))
    }
    
    
    
    
    /// 构建灯光数据
    /// - Parameters:
    ///   - color: 颜色
    ///   - isEnabled: 是否启用
    ///   - isSpeedEnabled: 启用速度
    ///   - speed: 速度
    /// - Returns: data
    static func buildLightData(_ color:Color,_ isEnabled:Bool=true,_ isSpeedEnabled:Bool = false,speed:Double) -> Data  {
        let colorData =  toRGBUInt8(color: color)
        return  ColorUtil.buildColorData(
            red: colorData.red,
            green: colorData.green,
            blue: colorData.blue,
            isEnabled: isEnabled,
            isSpeedEnabled: isSpeedEnabled,
            speed: speed
        )
    }
    
    static func buildTurnOff() -> Data {
      return  buildLightData(ColorUtil.argbToColor(argb: "#FF0092BD"),false,true, speed: 1)
    }
  
}

