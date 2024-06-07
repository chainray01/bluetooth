//
//  BLEManager.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/6.
//

import Foundation
import CoreBluetooth
class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isScanning = false // 是否正在扫描
    @Published var peripherals: [(peripheral: CBPeripheral, rssi: NSNumber, localName: String)] = [] // 发现的外围设备
    @Published var connectedPeripherals: Set<CBPeripheral> = [] // 已连接的外围设备
    @Published var characteristics: [CBPeripheral: [CBCharacteristic]] = [:] // 每个外围设备的特征值
    let  serviceUUID = CBUUID(string: "00007610-0000-1000-8000-00805F9B34FB")
    let characteristicUUID = CBUUID(string: "00007613-0000-1000-8000-00805F9B34FB")
    var centralManager: CBCentralManager!
    
    // 初始化 BLE 管理类
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        print("BLEManager 初始化")
    }

    // 开始扫描外围设备
    func startScanning() {
        if centralManager.state == .poweredOn {
            isScanning = true
            centralManager.scanForPeripherals(withServices: nil, options: nil)
            print("开始扫描外围设备")
        } else {
            print("中央管理器未开启")
        }
    }
    
    // 停止扫描外围设备
    func stopScanning() {
        isScanning = false
        centralManager.stopScan()
        print("停止扫描外围设备")
    }

    // 连接到指定的外围设备
    func connect(to peripheral: CBPeripheral) {
        centralManager.connect(peripheral, options: nil)
        if let localName = peripherals.first(where: { $0.peripheral == peripheral })?.localName {
            print("尝试连接到外围设备: \(localName)")
        }
    }
    
    // 中央管理器状态更新时调用
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("蓝牙已开启")
        case .poweredOff:
            print("蓝牙已关闭")
        case .resetting:
            print("蓝牙正在重置")
        case .unauthorized:
            print("蓝牙未授权")
        case .unsupported:
            print("蓝牙不支持")
        case .unknown:
            print("蓝牙状态未知")
        @unknown default:
            fatalError()
        }
    }

    // 发现外围设备时调用
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String,
           localName.hasPrefix("MD") || peripheral.name == "MD000000000000" {
            print("发现外围设备: \(localName) 信号强度: \(RSSI)")
            if !peripherals.contains(where: { $0.peripheral == peripheral }) {
                peripherals.append((peripheral, RSSI, localName))
                print("将设备添加到列表: \(localName) 信号强度: \(RSSI)")
            } else {
                if let index = peripherals.firstIndex(where: { $0.peripheral == peripheral }) {
                    peripherals[index].rssi = RSSI
                    peripherals[index].localName = localName
                    print("更新设备信号强度: \(localName) 信号强度: \(RSSI)")
                }
            }
            // 按 RSSI 信号强度对设备排序
            peripherals.sort { $0.rssi.intValue > $1.rssi.intValue }
        }
    }

    // 连接外围设备成功时调用
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripherals.insert(peripheral)
        if let localName = peripherals.first(where: { $0.peripheral == peripheral })?.localName {
            print("已连接到外围设备: \(localName)")
        }
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }

    // 发现服务时调用
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            if let localName = peripherals.first(where: { $0.peripheral == peripheral })?.localName {
                print("发现外围设备的服务: \(localName)")
            }
            for service in services{
                if service.uuid==serviceUUID{
                    print("发现服务的特征值: \(service.uuid)")
                    peripheral.discoverCharacteristics([characteristicUUID], for: service)
                }
            }
        } else {
            if let localName = peripherals.first(where: { $0.peripheral == peripheral })?.localName {
                print("发现服务失败: \(localName), 错误: \(error?.localizedDescription ?? "未知错误")")
            }
        }
    }

    // 发现特征值时调用
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            if let localName = peripherals.first(where: { $0.peripheral == peripheral })?.localName {
                print("发现服务的特征值: \(service.uuid) 在外围设备: \(localName)")
            }
            self.characteristics[peripheral, default: []].append(contentsOf: characteristics)
            for characteristic in characteristics {
                print("发现特征值: \(characteristic.uuid)")
                if characteristic.properties.contains(.read) {
                    peripheral.readValue(for: characteristic)
                    //print("读取特征值: \(characteristic.uuid)")
                }
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                    //print("设置特征值通知: \(characteristic.uuid)")
                }
            }
        } else {
            if let localName = peripherals.first(where: { $0.peripheral == peripheral })?.localName {
                print("发现特征值失败: \(service.uuid) 在外围设备: \(localName), 错误: \(error?.localizedDescription ?? "未知错误")")
            }
        }
    }

    // 读取特征值时调用
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            if let localName = peripherals.first(where: { $0.peripheral == peripheral })?.localName {
                print("收到数据来自 \(localName),uuid:\(characteristic.uuid),data: \(data)")
            }
        } else {
            if let localName = peripherals.first(where: { $0.peripheral == peripheral })?.localName {
                print("读取特征值失败: \(characteristic.uuid) 在外围设备: \(localName), 错误: \(error?.localizedDescription ?? "未知错误")")
            }
        }
    }

    // 写入数据到特征值
    func writeValue(_ data: Data, for characteristic: CBCharacteristic, on peripheral: CBPeripheral) {
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
        if let localName = peripherals.first(where: { $0.peripheral == peripheral })?.localName {
            print("写入数据到特征值: \(characteristic.uuid) 在外围设备: \(localName)")
        }
    }
    
    
    // 向所有已连接的设备写入数据
    func writeValueToAll(_ data: Data) {
        print("写入数据到所有已连接的外围设备")
        for peripheral in connectedPeripherals {
            if let characteristics = self.characteristics[peripheral] {
                for characteristic in characteristics {
                    // 检查特征值UUID是否匹配
                    if characteristic.uuid == CBUUID(string: "0000fff1-0000-1000-8000-00805f9b34fb") {
                        writeValue(data, for: characteristic, on: peripheral)
                    }
                }
            }
        }
    }
}

