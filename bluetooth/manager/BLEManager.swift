//
//  BLEManager.swift
//  bluetooth
//  BLE 控制器
//  Created by Ray chai on 2024/6/8.
//
import Foundation
import CoreBluetooth
import SwiftUI

class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isScanning = false
    @Published var peripherals: [(peripheral: CBPeripheral, rssi: NSNumber, localName: String?, groupTag: String?)] = []
    @Published var connectedPeripherals: Set<CBPeripheral> = []
    @Published var characteristics: [CBPeripheral: [CBCharacteristic]] = [:]

    let serviceUUID = CBUUID(string: "00007610-0000-1000-8000-00805F9B34FB")
    let characteristicUUID = CBUUID(string: "00007613-0000-1000-8000-00805F9B34FB")
    var centralManager: CBCentralManager!
    static let shared = BLEManager()

    private var scanTimer: Timer?
    private var sendWorkItems: [DispatchWorkItem] = []
    private var stopSendFlag = false

    override private init() {
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
            fatalError()
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
        
      
        
        if localName.hasPrefix("MD") || peripheral.name == "MD000000000000" {
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
        peripheral.discoverServices([serviceUUID])
        print("Connected to peripheral: \(peripheral.identifier)")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let index = peripherals.firstIndex(where: { $0.peripheral == peripheral }) {
            peripherals.remove(at: index)
        }
        connectedPeripherals.remove(peripheral)
        characteristics.removeValue(forKey: peripheral)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            print("Failed to discover services for peripheral: \(peripheral.identifier), error: \(error?.localizedDescription ?? "unknown error")")
            return
        }
        
        for service in services {
            if service.uuid == serviceUUID {
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
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
        print("Received data from peripheral: \(peripheral.identifier), characteristic: \(characteristic.uuid), data: \(data)")
    }



    func writeValue(_ data: Data, for characteristic: CBCharacteristic, on peripheral: CBPeripheral) {
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
    }

 
    
    func disconnect(peripheral: CBPeripheral) {
        let data = ColorUtil.buildTurnOff()
        if let characteristics = self.characteristics[peripheral] {
            for characteristic in characteristics where characteristic.uuid == characteristicUUID {
                peripheral.writeValue(data, for: characteristic, type: .withResponse)
            }
        }
        centralManager.cancelPeripheralConnection(peripheral)
        connectedPeripherals.remove(peripheral)
        if let index = peripherals.firstIndex(where: { $0.peripheral == peripheral }) {
            peripherals.remove(at: index)
        }
        characteristics.removeValue(forKey: peripheral)
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
    func sort(){
        peripherals.sort { $0.rssi.intValue > $1.rssi.intValue }
    }
    private func startTimer() {
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
        scanTimer!.fireDate = Date().addingTimeInterval(1)
        RunLoop.main.add(scanTimer!, forMode: .common)
    }
 
}
 
