//
//  Constants.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/18.
//

import CoreBluetooth

struct Constants {
    // 私有化初始化方法，禁止实例化
    private init() {}
    
  //只能为Uint8 0～255
  static let maxSpeed: Double = 30.0
  static let serviceUUID = CBUUID(string: "00007610-0000-1000-8000-00805F9B34FB")
  static let characteristicUUID = CBUUID(string: "00007613-0000-1000-8000-00805F9B34FB")
  
  static let deviceNamePrefixes: Set<String> = ["MD187A93", "CD187A93", "B5187A93", "B2187A93"]
    
  // 定义颜色映射
  static let colorMappings: [[String]] = [
    ["red4", "#ef4444"],
    ["red3", "#f87171"],
    ["red2", "#fca5a5"],
    ["red1", "#fecaca"],
    ["ora4", "#f97316"],
    ["ora3", "#fb923c"],
    ["ora2", "#fdba74"],
    ["ora1", "#fed7aa"],
    ["yel4", "#eab308"],
    ["yel3", "#facc15"],
    ["yel2", "#fde047"],
    ["yel1", "#fef08a"],
    ["sky4", "#06b6d4"],
    ["sky3", "#22d3ee"],
    ["sky2", "#67e8f9"],
    ["sky1", "#a5f3fc"],
    ["blu4", "#3b82f6"],
    ["blu3", "#60a5fa"],
    ["blu2", "#93c5fd"],
    ["blu1", "#bfdbfe"],
    ["pur4", "#a855f7"],
    ["pur3", "#c084fc"],
    ["pur2", "#d8b4fe"],
    ["pur1", "#e9d5ff"],
    ["redT", "#ef4444"],
    ["oraT", "#f97316"],
    ["yelT", "#eab308"],
    ["skyT", "#06b6d4"],
    ["bluT", "#3b82f6"],
    ["purT", "#a855f7"],
    ["off4", "#333333"],
    ["pin4", "#ec4899"],
    ["pin2", "#f472b6"],
    ["whi4", "#ffffff"],
    ["whiT", "#eeeeee"],
   // ["rai4", "rainbow"],
  ]

  // 缓存的命令数据字典，使用 lazy 属性确保延迟初始化
  private static let _commandDataDictionary: [String: ColorCommand] = {
    var commandDataDictionary = [String: ColorCommand]()

    for color in colorMappings {
      guard let key = color[0] as String?,
        let colorCode = color[1] as String?
      else {
        continue
      }
      let isTextColor = key.hasSuffix("T")
      let speedFlag: UInt8 = isTextColor ? 1 : 0
      let speed: UInt8 = 0

      let color = ColorUtil.argbToColor(argb: colorCode)
      let rgb = ColorUtil.toRGBUInt8(color: color)
      if let command = ColorCommand(
        r: rgb.red, g: rgb.green, b: rgb.blue,
        enabledFlag: 1, speedFlag: speedFlag, speed: speed)
      {
        commandDataDictionary[key] = command
      }
    }
    return commandDataDictionary
  }()

  // 获取命令数据字典
  static var commandDataDictionary: [String: ColorCommand] {
    return _commandDataDictionary
  }
}
