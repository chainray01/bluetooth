//
//  Constants.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/18.
//


import CoreBluetooth
struct Constants {
    
    //只能为Uint8 0～255
    static   let maxSpeed: Double = 30.0
    static   let serviceUUID = CBUUID(string: "00007610-0000-1000-8000-00805F9B34FB")
    static   let characteristicUUID = CBUUID(string: "00007613-0000-1000-8000-00805F9B34FB")
    
    struct Colors {
        // static let primaryColor = UIColor(red: 0.0, green: 122/255.0, blue: 1.0, alpha: 1.0)
        // static let secondaryColor = UIColor(red: 1.0, green: 149/255.0, blue: 0.0, alpha: 1.0)
    }
}
