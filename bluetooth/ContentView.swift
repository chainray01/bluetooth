//
//  ContentView.swift
//  bluetooth
//
//  Created by Ray chai on 2024/5/28.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @ObservedObject var bleManager = BLEManager()
    @State private var filterText = ""
    @State private var selectedColor = Color.red
    @State private var selectedSpeed   = Int(UInt8.min)
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
                .onChange(of: selectedColor) {
                    newValue in
                        sendColorAndSpeed()}
                .padding()
            
       
            // Slider for speed selection
            Slider(value: Binding(
                get: { Double(selectedSpeed) },
                set: { selectedSpeed = Int($0) }
            ), in: Double(UInt8.min)...Double(UInt8.max), step: 1)
                .padding()
                .onChange(of: selectedSpeed) { newSpeed in
                    sendColorAndSpeed()
                }
            
            Text("Selected speed: \( selectedSpeed)")
                .padding()

            .pickerStyle(SegmentedPickerStyle())
            .padding()
        }
    }
    
    func sendColorAndSpeed() {
        let colorData =  toRGBUInt8(color:selectedColor)
        let speedData = selectedSpeed
        let data = bleManager.buildColorData(red: colorData.red,green: colorData.green,blue: colorData.blue, speed: speedData)
        bleManager.writeValueToAll(data)
    }
}

func toRGBUInt8(color:Color) -> (red: UInt8, green: UInt8, blue: UInt8) {
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

#Preview {
    ContentView()
}
