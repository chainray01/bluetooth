//
//  ColorCommand.swift
//  bluetooth
//
//  Created by Ray chai on 2024/7/18.
//

import Foundation

// 定义结构体
struct ColorCommand {
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    var enabledFlag: UInt8
    var speedFlag: UInt8
    var speed: UInt8

    init?(r red: UInt8,g green: UInt8,b blue: UInt8, enabledFlag: UInt8, speedFlag: UInt8, speed: UInt8) {
        self.red = red
        self.green = green
        self.blue = blue
        self.enabledFlag = enabledFlag
        self.speedFlag = speedFlag
        self.speed = speed
    }

    func toData() -> Data {
        var commandData = Data(count: 8)
        commandData[0] = 0xAA
        commandData[1] = 0xA1
        commandData[2] = red
        commandData[3] = green
        commandData[4] = blue
        commandData[5] = enabledFlag
        commandData[6] = speedFlag
        commandData[7] = speed
        return commandData
    }
}
