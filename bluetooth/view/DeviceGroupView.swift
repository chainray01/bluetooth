//
//  DeviceGroupView.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/12.
//

import SwiftUI
import CoreBluetooth

/// 设备分组视图，允许用户选择设备分组并为其选择颜色
struct DeviceGroupView: View {
    @Binding var selectedColor: Color
    @State private var selectedGroup: Int = 0
    @State private var groupColors: [Int: Color] = [:]
    @State private var deviceGroups: [Int: [CBPeripheral]] = [:]
    @State private var selectedDevice: CBPeripheral?
    @State private var showDevicePicker: Bool = false

    @ObservedObject var bleManager = BLEManager.shared

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(0..<4) { group in
                    VStack {
                        Circle()
                            .fill(groupColors[group] ?? .gray)
                            .frame(width: 45, height: 45)
                            .onTapGesture {
                                selectedGroup = group
                                groupColors[group] = selectedColor
                            }
                        Button(action: { showDevicePicker.toggle() }) {
                            Text("分组 \(group + 1)")
                                .font(.caption)
                                .padding(5)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            Spacer()
        }
        .sheet(isPresented: $showDevicePicker) {
            GeometryReader { geometry in
                VStack {
                    Text("选择设备")
                        .font(.headline)
                        .padding()

                    List(Array(bleManager.connectedPeripherals), id: \.self) { peripheral in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(peripheral.name ?? "设备")
                                    .font(.body)
                                Text(peripheral.identifier.uuidString)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            if deviceGroups[selectedGroup]?.contains(peripheral) == true {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            // 移除设备之前的分组
                            for (group, devices) in deviceGroups {
                                if let index = devices.firstIndex(of: peripheral) {
                                    deviceGroups[group]?.remove(at: index)
                                    break
                                }
                            }
                            // 更新设备的新分组
                            if deviceGroups[selectedGroup] == nil {
                                deviceGroups[selectedGroup] = []
                            }
                            deviceGroups[selectedGroup]?.append(peripheral)
                            self.selectedDevice = peripheral
                            showDevicePicker = false
                        }
                    }
                    .listStyle(PlainListStyle()) // 使用简洁的列表样式
                }
                .padding()
                .frame(height: geometry.size.height / 2) // 设置弹框高度为屏幕高度的一半
            }
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
    DeviceGroupView(selectedColor: .constant(Color.white))
}
