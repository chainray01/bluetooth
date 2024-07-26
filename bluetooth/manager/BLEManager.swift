//
//  BLEManager.swift
//  bluetooth
//  BLE 控制器
//  Created by Ray chai on 2024/6/8.
//

import CoreBluetooth

final class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isScanning = false
    @Published var peripherals: [(peripheral: CBPeripheral, rssi: NSNumber, localName: String?, groupTag: String?)] = []
    @Published var connectedPeripherals: Set<CBPeripheral> = []
    @Published var characteristics: [CBPeripheral: [CBCharacteristic]] = [:]
    
    private var centralManager: CBCentralManager!
    private var scanTimer: Timer?
    private let centralQueue = DispatchQueue(label: "com.ray.centralQueue")
    
    static let shared = BLEManager()
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        print("BLEManager initialized")
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
            startScanning()
        case .poweredOff, .resetting, .unauthorized, .unsupported, .unknown:
            print("Bluetooth is \(central.state)")
            stopScanningAndTimer()
        @unknown default:
            stopScanningAndTimer()
            fatalError("Unknown Bluetooth state")
        }
    }
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("Central manager is not powered on, current state: \(centralManager.state.rawValue)")
            return
        }
        isScanning = true
        startTimer()
        print("Started scanning for peripherals")
    }
    
    func stopScanning() {
        guard isScanning else { return }
        isScanning = false
        centralManager.stopScan()
        stopTimer()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String else { return }
        
        if let index = peripherals.firstIndex(where: { $0.peripheral == peripheral }) {
            peripherals[index].rssi = RSSI
            peripherals[index].localName = localName
        } else {
            peripherals.append((peripheral, RSSI, localName, nil))
        }
        
        if Constants.deviceNamePrefixes.contains(where: localName.hasPrefix) {
            connect(to: peripheral)
        }
    }
    
    func connect(to peripheral: CBPeripheral) {
        guard !connectedPeripherals.contains(peripheral) else { return }
        centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripherals.insert(peripheral)
        peripheral.delegate = self
        peripheral.discoverServices([Constants.serviceUUID])
        print("Connected to peripheral: \(peripheral.identifier)")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectedPeripherals.remove(peripheral)
        characteristics.removeValue(forKey: peripheral)
        peripherals.removeAll { $0.peripheral == peripheral }
        if let error = error {
            print("Disconnected from peripheral: \(peripheral.identifier) with error: \(error.localizedDescription)")
        } else {
            print("Disconnected from peripheral: \(peripheral.identifier)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            print("Failed to discover services for peripheral: \(peripheral.identifier), error: \(error?.localizedDescription ?? "unknown error")")
            return
        }
        
        for service in services where service.uuid == Constants.serviceUUID {
            print("Discovered service: \(service.uuid) for peripheral: \(peripheral.identifier)")
            peripheral.discoverCharacteristics([Constants.characteristicUUID], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            print("Failed to discover characteristics for service: \(service.uuid), error: \(error?.localizedDescription ?? "unknown error")")
            return
        }
        
        self.characteristics[peripheral, default: []].append(contentsOf: characteristics)
        
        for characteristic in characteristics {
            if characteristic.properties.contains(.read) {
                peripheral.readValue(for: characteristic)
            }
            if characteristic.properties.contains(.notify) {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else {
            print("Failed to read value for characteristic: \(characteristic.uuid), error: \(error?.localizedDescription ?? "unknown error")")
            return
        }
        // Handle received data
    }
    
    func writeValue(_ data: Data, for characteristic: CBCharacteristic, on peripheral: CBPeripheral) {
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }
    
    func filterPeripherals(by groupTag: String) -> [CBPeripheral] {
        return peripherals.filter { $0.groupTag == groupTag }.map { $0.peripheral }
    }
    
    func disconnect(peripheral: CBPeripheral) {
        let data = ColorUtil.buildTurnOff()
        if let characteristics = self.characteristics[peripheral] {
            for characteristic in characteristics where characteristic.uuid == Constants.characteristicUUID {
                peripheral.writeValue(data, for: characteristic, type: .withResponse)
            }
        }
       //断开连接后自动重连：断开连接后，除非您明确指示，否则设备不会自动重新连接。
        //centralManager.cancelPeripheralConnection(peripheral)
    }
    
    func toggleScanning() {
        isScanning ? stopScanning() : startScanning()
    }
    
    private func stopScanningAndTimer() {
        stopScanning()
        stopTimer()
    }
    
    private func stopTimer() {
        scanTimer?.invalidate()
        scanTimer = nil
    }
    
    func sort() {
        peripherals.sort { $0.rssi.intValue > $1.rssi.intValue }
    }
    
    private func startTimer() {
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
        scanTimer?.fireDate = Date().addingTimeInterval(1)
        RunLoop.main.add(scanTimer!, forMode: .common)
    }
}
