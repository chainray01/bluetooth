//
//  ContentView.swift
//  bluetooth
//
//  Created by Ray chai on 2024/5/28.
//

import SwiftUI
import CoreBluetooth
import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @ObservedObject var bleManager = BLEManager()
    @State private var filterText = ""
    @State private var selectedColor = Color.red
    @State private var selectedSpeed = 1

    var filteredPeripherals: [(peripheral: CBPeripheral, rssi: NSNumber, localName: String)] {
        if filterText.isEmpty {
            return bleManager.peripherals
        } else {
            return bleManager.peripherals.filter { $0.localName.contains(filterText) }
        }
    }

    var body: some View {
        VStack {
            HStack {
                Text("BLE 设备")
                    .font(.largeTitle)
                    .padding()
            }
            TextField("按名称筛选", text: $filterText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            List(filteredPeripherals, id: \.peripheral.identifier) { item in
                VStack(alignment: .leading) {
                    Text(item.localName)
                    Text("信号强度 (RSSI): \(item.rssi)")
                }
            }

            if !bleManager.connectedPeripherals.isEmpty {
                VStack {
                    Text("已连接的设备数: \(bleManager.connectedPeripherals.count) 个")
                    Button(action: {
                        sendColorAndSpeed()
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

            ColorPicker("选择颜色", selection: $selectedColor)
                .padding()

            Picker("选择速度", selection: $selectedSpeed) {
                ForEach(1...10, id: \.self) { speed in
                    Text("\(speed)").tag(speed)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
        }
    }

    func sendColorAndSpeed() {
        let colorData = selectedColor.description.data(using: .utf8) ?? Data()
        let speedData = "\(selectedSpeed)".data(using: .utf8) ?? Data()
        let combinedData = colorData + speedData
        bleManager.writeValueToAll(combinedData)
    }
}
 

#Preview {
    ContentView()
}
