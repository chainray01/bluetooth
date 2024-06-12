//
//  DeviceGroupView.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/12.
//

import SwiftUI

import SwiftUI
import CoreBluetooth

/// 设备分组视图，允许用户选择设备分组并为其选择颜色
struct DeviceGroupView: View {
    @Binding var selectedColor: Color 
    @State private var selectedGroup: Int = 0
    @State private var groupColors: [Int: Color] = [:]
    @State private var deviceGroups: [CBPeripheral: Int] = [:]
    @State private var selectedDevice: CBPeripheral?
    @State private var showDevicePicker: Bool = false

    @ObservedObject var bleManager = BLEManager.shared
    var body: some View {
        VStack(spacing: 20) {
            Button(action: {
                showDevicePicker.toggle()
            }) {
                Text("选择设备分组并设置颜色")
                    .font(.headline)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            HStack(spacing: 20) {
                ForEach(0..<4) { group in
                    VStack {
                        Text("分组 \(group + 1)")
                            .font(.caption)
                        Circle()
                            .fill(groupColors[group] ?? .gray)
                            .frame(width: 45, height: 45)
                            .onTapGesture {
                                selectedGroup = group
                                groupColors[group] = selectedColor
                            }
                    }
                }
            }

            if let selectedDevice = selectedDevice {
                Text("已选择设备: \(selectedDevice.name ?? "设备")")
                    .foregroundColor(.blue)
            }

            Spacer()
        }
        .sheet(isPresented: $showDevicePicker) {
            VStack {
                Text("选择设备")
                    .font(.headline)
                    .padding()

                List(Array(connectedPeripherals), id: \.self) { peripheral in
                    HStack {
                        Text(peripheral.name ?? "设备")
                        Spacer()
                        if deviceGroups[peripheral] == selectedGroup {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        // 移除设备之前的分组
                        if let oldGroup = deviceGroups[peripheral] {
                            deviceGroups[peripheral] = nil
                        }
                        // 更新设备的新分组
                        deviceGroups[peripheral] = selectedGroup
                        self.selectedDevice = peripheral
                        showDevicePicker = false
                    }
                }
            }
            .padding()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding()
    }
}
#Preview {
    DeviceGroupView()
}
