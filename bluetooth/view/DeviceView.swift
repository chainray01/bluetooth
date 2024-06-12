//
//  DeviceView.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/12.
//

import SwiftUI

struct DeviceView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @State private var selectedPeripherals = Set<UUID>()
    @State private var isBatchModeActive = false

    var body: some View {
        VStack {
            HStack {
                Text("BLE Devices")
                    .font(.largeTitle)
                    .padding(.leading)
                Spacer()
                Button(isBatchModeActive ? "取消" : "设置分组") {
                    withAnimation {
                        isBatchModeActive.toggle()
                    }
                    if !isBatchModeActive {
                        selectedPeripherals.removeAll() // Clear selections when batch mode is deactivated
                    }
                }
                .padding(.trailing)
            }
            .padding(.top)
            
            if isBatchModeActive  {
                HStack {
                    Spacer()
                    ForEach(["A", "B", "C", "D"], id: \.self) { tag in
                        Button("\(tag)") {
                            withAnimation {
                                for id in selectedPeripherals {
                                    if let index = bleManager.peripherals.firstIndex(where: { $0.peripheral.identifier == id }) {
                                        bleManager.peripherals[index].groupTag = tag
                                    }
                                }
                                selectedPeripherals.removeAll() // Clear selections after setting the group
                                isBatchModeActive = false // Exit batch mode after setting the group
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(5)
                    }
                    Spacer()
                }
                .padding(.bottom, 10)
                .transition(.opacity) // Smoothly fade in/out the buttons
            }

            List {
                ForEach(Array(bleManager.connectedPeripherals), id: \.identifier) { peripheral in
                    if let device = bleManager.peripherals.first(where: { $0.peripheral == peripheral }) {
                        HStack {
                            if isBatchModeActive {
                                Image(systemName: selectedPeripherals.contains(peripheral.identifier) ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(selectedPeripherals.contains(peripheral.identifier) ? .blue : .gray)
                                    .onTapGesture {
                                        if selectedPeripherals.contains(peripheral.identifier) {
                                            selectedPeripherals.remove(peripheral.identifier)
                                        } else {
                                            selectedPeripherals.insert(peripheral.identifier)
                                        }
                                    }
                                    .padding(.trailing, 5)
                            }
                            
                            VStack(alignment: .leading, spacing: 5) {
                                if let localName = device.localName {
                                    Text(localName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                } else {
                                    Text(peripheral.identifier.uuidString)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                Text("信号强度 (RSSI): \(device.rssi)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Text("已连接")
                                .font(.caption)
                                .padding(3)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(3)
                            Menu {
                                ForEach(["A", "B", "C", "D"], id: \.self) { tag in
                                    Button(action: {
                                        if let index = bleManager.peripherals.firstIndex(where: { $0.peripheral == peripheral }) {
                                            bleManager.peripherals[index].groupTag = tag
                                        }
                                    }) {
                                        HStack {
                                            Text(tag)
                                            if device.groupTag == tag {
                                                Spacer()
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: 2) {
                                    Text(device.groupTag ?? "分组")
                                        .font(.caption)
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .padding(3)
                                .background(Color.blue.opacity(0.2))
                                .cornerRadius(3)
                            }
                        }
                        .padding(10)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(10)
                        .listRowBackground(Color.clear)
                        .padding(.vertical, 2)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .background(Color.clear)
        }
        .padding(.bottom, 25)
        .animation(.default, value: isBatchModeActive)
    }
}

#Preview {
    DeviceView()
}
