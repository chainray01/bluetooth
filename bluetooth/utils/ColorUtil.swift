//
//  ColorUtil.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/8.
//

import Foundation
import SwiftUI

class ColorUtil {

  //颜色转rbg分量
  static func toRGBUInt8(color: Color) -> (red: UInt8, green: UInt8, blue: UInt8) {
    let components = color.cgColor?.components
    let red = components?[0] ?? 0
    let green = components?[1] ?? 0
    let blue = components?[2] ?? 0
    return ( UInt8(red * 255), UInt8(green * 255), UInt8(blue * 255)
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
  /// - Returns: [170, 161, 0, 146, 189, 255, 255, 20]
  static func buildColorData( red: UInt8, green: UInt8, blue: UInt8, isEnabled: Bool = true, isSpeedEnabled: Bool = false, speed: Double) -> Data {

    // Set the "enabled" and "speed" flags true255 /false0
    let enabledFlag: UInt8 = isEnabled ? 255 : 0
    let speedFlag: UInt8 = isSpeedEnabled ? 255 : 0
 
    // Create an 8-byte array to hold the command data
    var commandData = Data(count: 8)

    // Set the fixed command header 170 161
    commandData[0] = 0xAA
    commandData[1] = 0xA1

    // Set the RGB values
    commandData[2] = red
    commandData[3] = green
    commandData[4] = blue

    // Set the "enabled" and "speed" flags
    commandData[5] = enabledFlag
    commandData[6] = speedFlag

    // Set the calculated speed value
    commandData[7] =  UInt8(Constants.maxSpeed - speed)
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
    let alpha = CGFloat((argbValue & 0xFF00_0000) >> 24) / 255.0
    let red = CGFloat((argbValue & 0x00FF_0000) >> 16) / 255.0
    let green = CGFloat((argbValue & 0x0000_FF00) >> 8) / 255.0
    let blue = CGFloat(argbValue & 0x0000_00FF) / 255.0
    return Color(cgColor: .init(srgbRed: red, green: green, blue: blue, alpha: alpha))
  }

    
    
  /// 构建灯光数据
  /// - Parameters:
  ///   - color: 颜色
  ///   - isEnabled: 是否启用
  ///   - isSpeedEnabled: 启用速度
  ///   - speed: 速度
  /// - Returns: data
  static func buildColor( _ color: Color, _ isEnabled: Bool = true, _ isSpeedEnabled: Bool = false, speed: Double) -> Data {
    let colorData = toRGBUInt8(color: color)
    return buildColorData(
      red: colorData.red,
      green: colorData.green,
      blue: colorData.blue,
      isEnabled: isEnabled,
      isSpeedEnabled: isSpeedEnabled,
      speed: speed
    )
  }
    
    
    

  static func buildTurnOff() -> Data {
    return buildColor(ColorUtil.argbToColor(argb: "#FF0092BD"), false, true, speed: 1)
  }

}
