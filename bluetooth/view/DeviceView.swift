import SwiftUI
import Foundation
import CoreBluetooth

struct DeviceView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @State private var selectedPeripherals = Set<UUID>()
    @State private var isBatchModeActive = false
    @State private var showConnected = false
    @State private var currentDeviceName: String = ""

    var  cu = WriteDataUtil.shared
    private var dataManager = DatabaseManager.shared
    
    var allSelected: Bool {
        selectedPeripherals.count == bleManager.connectedPeripherals.count
    }

    var body: some View {
        VStack {
            header
            deviceList
            if isBatchModeActive {
                batchActions
            }
        }
        .padding(.bottom, 10)
        .onChange(of: selectedPeripherals) { _ in
            if selectedPeripherals.count == bleManager.connectedPeripherals.count {
              //  print("All peripherals selected")
            }
        }
    }

    /// Header view containing the title and action buttons
    private var header: some View {
        HStack {
            Text("BLE Devices")
                .font(.title3)
                .padding(.leading)
            Spacer()
            Button(action: toggleBatchMode) {
                Label(isBatchModeActive ? "取消" : "批量", systemImage: "square.and.pencil")
            }
            ZStack {
                Menu {
                    Button(action: {
                        bleManager.toggleScanning()
                    }) {
                        Label(bleManager.isScanning ? "点击暂停扫描" : "启动扫描", systemImage: "magnifyingglass")
                    }
                    
                    Button(action: {
                        bleManager.sort()
                    }) {
                        Label("排序", systemImage: "line.horizontal.3.decrease.circle")
                    }
                    Button(action: {
                        showConnected.toggle()
                    }) {
                        Label(!showConnected ? "展示所有设备" : "展示已连接的设备", systemImage: "line.horizontal.3.decrease.circle")
                    }
                    
                    Button(action: {
                        if bleManager.connectedPeripherals.count > 0 {
                            bleManager.toggleScanning()
                            cu.disconnectAll()
                        }
                    }) {
                        Label("断开所有设备连接", systemImage: "xmark.circle")
                            .foregroundColor(bleManager.connectedPeripherals.count > 0 ? .blue : .gray)
                    }
                    .disabled(bleManager.connectedPeripherals.count == 0)
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.title2).foregroundColor(Color.gray)
                        .padding()
                        .frame(minWidth: 50) // Adjust width here as needed
                }
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.1))
    }
    /// List view displaying the devices
    private var deviceList: some View {
        List {
            ForEach(bleManager.peripherals, id: \.peripheral.identifier) { device in
                if showConnected && bleManager.connectedPeripherals.contains(device.peripheral) {
                    deviceRow(for: device)
                } else {
                    deviceRow(for: device)
                }
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.clear)
    }

    /// Row view for each device
    private func deviceRow(for device: (peripheral: CBPeripheral, rssi: NSNumber, localName: String?, groupTag: String?)) -> some View {
        HStack {
            if isBatchModeActive {
                if bleManager.connectedPeripherals.contains(device.peripheral) {
                    selectionIcon(for: device.peripheral.identifier)
                        .padding(.trailing, 5)
                }
            }
            deviceInfo(for: device)
            Spacer()
            if bleManager.connectedPeripherals.contains(device.peripheral) {
                let uname: String? = dataManager.fetchDeviceName(id: device.peripheral.identifier.uuidString)
                TextField(uname ?? "自定义名称", text: $currentDeviceName, onCommit: {
                    dataManager.deleteDevice(id: device.peripheral.identifier.uuidString)
                    if currentDeviceName != ""{
                        dataManager.insertDevice(id: device.peripheral.identifier.uuidString, name: currentDeviceName)
                    }
                    
                    
                })
                .padding(3)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(3)
                .frame(maxWidth: 50)
                connectionStatus
                groupMenu(for: device)
            }
        }
        .padding(10)
        .cornerRadius(10)
        .listRowBackground(Color.clear)
        .padding(.vertical, 2)
    }

    /// Selection icon for batch mode
    private func selectionIcon(for identifier: UUID) -> some View {
        Image(systemName: selectedPeripherals.contains(identifier) ? "checkmark.circle.fill" : "circle")
            .foregroundColor(selectedPeripherals.contains(identifier) ? .blue : .gray)
            .onTapGesture {
                toggleSelection(for: identifier)
            }
    }

    /// Device information view
    private func deviceInfo(for device: (peripheral: CBPeripheral, rssi: NSNumber, localName: String?, groupTag: String?)) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(device.localName ?? device.peripheral.identifier.uuidString)
                .font(.headline)
                .foregroundColor(.primary)
            Text("信号强度 (RSSI): \(device.rssi)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    /// Connection status view
    private var connectionStatus: some View {
        Text("已连接")
            .font(.caption)
            .padding(5)
            .background(Color.green.opacity(0.2))
            .cornerRadius(3)
    }

    /// Group menu for device grouping
    private func groupMenu(for device: (peripheral: CBPeripheral, rssi: NSNumber, localName: String?, groupTag: String?)) -> some View {
        Menu {
            ForEach(["A", "B", "C", "D"], id: \.self) { tag in
                Button(action: {
                    setGroupTag(tag, for: device.peripheral)
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
            .padding(5)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(3)
        }
    }

    /// Batch actions view
    private var batchActions: some View {
        HStack {
            Button(allSelected ? "取消全选" : "全选") {
                toggleSelectAll()
            }
            .padding()
            Spacer()
            Menu {
                ForEach(["A", "B", "C", "D"], id: \.self) { tag in
                    Button(action: {
                        setGroupTagForSelected(tag)
                    }) {
                        Text(tag)
                    }
                }
            } label: {
                HStack(spacing: 2) {
                    Text("分组")
                        .font(.caption)
                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .padding(5)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(3)
            }
            .padding()
        }
        .padding(3)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }

    /// Toggles batch mode
    private func toggleBatchMode() {
        withAnimation {
            isBatchModeActive.toggle()
        }
        if !isBatchModeActive {
            selectedPeripherals.removeAll()
        }
    }

    /// Toggles selection for a specific device
    private func toggleSelection(for identifier: UUID) {
        if selectedPeripherals.contains(identifier) {
            selectedPeripherals.remove(identifier)
        } else {
            selectedPeripherals.insert(identifier)
        }
    }

    /// Toggles selection for all devices
    private func toggleSelectAll() {
        if allSelected {
            selectedPeripherals.removeAll()
            toggleBatchMode()
        } else {
            selectedPeripherals = Set(bleManager.connectedPeripherals.map { $0.identifier })
        }
    }

    /// Sets group tag for a specific device
    private func setGroupTag(_ tag: String, for peripheral: CBPeripheral) {
        if let index = bleManager.peripherals.firstIndex(where: { $0.peripheral == peripheral }) {
            bleManager.peripherals[index].groupTag = tag
        }
    }

    /// Sets group tag for all selected devices
    private func setGroupTagForSelected(_ tag: String) {
        for selectedPeripheral in selectedPeripherals {
            if let index = bleManager.peripherals.firstIndex(where: { $0.peripheral.identifier == selectedPeripheral }) {
                bleManager.peripherals[index].groupTag = tag
            }
        }
    }
}

#Preview {
    DeviceView()
}
