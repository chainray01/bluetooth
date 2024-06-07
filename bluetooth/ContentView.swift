//
//  ContentView.swift
//  bluetooth
//
//  Created by Ray chai on 2024/5/28.
//

import SwiftUI
import CoreBluetooth
struct ContentView: View {
    @ObservedObject var bleManager = BLEManager() // 观察 BLE 管理类的对象
    @State private var filterText = "" // 筛选文本

    // 根据筛选文本筛选设备
    var filteredPeripherals: [(peripheral: CBPeripheral, rssi: NSNumber, localName: String)] {
        if filterText.isEmpty {
            return bleManager.peripherals
        } else {
            return bleManager.peripherals.filter { $0.localName.contains(filterText) }
        }
    }

    var body: some View {
        VStack {
            // 顶部工具栏
            HStack {
                // 启动或停止扫描按钮
                Button(action: {
                    bleManager.isScanning ? bleManager.stopScanning() : bleManager.startScanning()
                }) {
                    Text(bleManager.isScanning ? "停止扫描" : "开始扫描")
                }
                .padding()
                
                // 标题
                Text("BLE 设备")
                    .font(.largeTitle)
                    .padding()
            }
            
            // 筛选框
            TextField("按名称筛选", text: $filterText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            // 列表显示扫描到的外围设备
            List(filteredPeripherals, id: \.peripheral.identifier) { item in
                VStack(alignment: .leading) {
                    Text(item.localName)
                    Text("信号强度 (RSSI): \(item.rssi)")
                    Button(action: {
                        // 连接到所选设备
                        bleManager.connect(to: item.peripheral)
                    }) {
                        Text("连接")
                    }
                }
            }
            
            // 如果已连接设备，显示其特征值
            if !bleManager.connectedPeripherals.isEmpty {
                VStack {
                    Text("已连接的设备数: \(bleManager.connectedPeripherals.count) 个")
                    Button(action: {
                        if let data = "Hello BLE".data(using: .utf8) {
                            // 向所有已连接设备发送数据
                            bleManager.writeValueToAll(data)
                        }
                    }) {
                        Text("发送数据到所有设备")
                    }
                    ForEach(Array(bleManager.connectedPeripherals), id: \.identifier) { peripheral in
                        VStack {
                            if let localName = bleManager.peripherals.first(where: { $0.peripheral == peripheral })?.localName {
                                Text("设备: \(localName)")
                            }
                            if let characteristics = bleManager.characteristics[peripheral] {
                                ForEach(characteristics, id: \.uuid) { characteristic in
                                    Text("特征值: \(characteristic.uuid)")
                                
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    ContentView()
}
