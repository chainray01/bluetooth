import Foundation
import CoreBluetooth
import SwiftUI
class BLEManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var isScanning = false // 是否正在扫描
    @Published var peripherals: [(peripheral: CBPeripheral, rssi: NSNumber, localName: String?)] = [] // 发现的外围设备
    @Published var connectedPeripherals: Set<CBPeripheral> = [] // 已连接的外围设备
    @Published var characteristics: [CBPeripheral: [CBCharacteristic]] = [:] // 每个外围设备的特征值

    let serviceUUID = CBUUID(string: "00007610-0000-1000-8000-00805F9B34FB")
    let characteristicUUID = CBUUID(string: "00007613-0000-1000-8000-00805F9B34FB")
    var centralManager: CBCentralManager!
    static let shared = BLEManager()

    var scanTimer: Timer?
    private var sendWorkItems: [DispatchWorkItem] = []
    private var isSending = false

    override private init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        print("BLEManager 初始化")
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("蓝牙已开启")
            startScanning()
        case .poweredOff:
            print("蓝牙已关闭")
            stopScanning()
            stopTimer()
        case .resetting:
            print("蓝牙正在重置")
            stopScanning()
            stopTimer()
        case .unauthorized:
            print("蓝牙未授权")
            stopScanning()
            stopTimer()
        case .unsupported:
            print("蓝牙不支持")
            stopScanning()
            stopTimer()
        case .unknown:
            print("蓝牙状态未知")
            stopScanning()
            stopTimer()
        @unknown default:
            stopScanning()
            stopTimer()
            fatalError()
        }
    }

    func startScanning() {
        if centralManager.state == .poweredOn {
            isScanning = true
            scanTimer?.invalidate()
            startTimer()
            print("开始扫描外围设备")
        } else {
            print("中央管理器未开启，当前状态: \(centralManager.state.rawValue)")
        }
    }

    func stopScanning() {
        if isScanning {
            isScanning = false
            centralManager.stopScan()
            stopTimer()
         }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            if !peripherals.contains(where: { $0.peripheral == peripheral }) {
                peripherals.append((peripheral, RSSI, localName))
               // print("将设备添加到列表: \(localName) 信号强度: \(RSSI)")
            } else {
                if let index = peripherals.firstIndex(where: { $0.peripheral == peripheral }) {
                    peripherals[index].rssi = RSSI
                    peripherals[index].localName = localName
                  //  print("更新设备信号强度: \(localName) 信号强度: \(RSSI)")
                }
            }
            peripherals.sort { $0.rssi.intValue > $1.rssi.intValue }
            if localName.hasPrefix("MD") || peripheral.name == "MD000000000000" {
                connect(to: peripheral)
            }
        }
    }

    func connect(to peripheral: CBPeripheral) {
        if !connectedPeripherals.contains(peripheral) {
            centralManager.connect(peripheral, options: nil)
//            if let localName = peripherals.first(where: { $0.peripheral == peripheral })?.localName {
//                print("尝试连接到外围设备: \(localName)")
//            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripherals.insert(peripheral)
        if let localName = peripherals.first(where: { $0.peripheral == peripheral })?.localName {
            print("已连接到外围设备: \(localName)")
        }
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {

//        if let localName = peripherals.first(where: { $0.peripheral == peripheral })?.localName {
//            print("外围设备断开连接: \(localName)")
//        }
        if let index = peripherals.firstIndex(where: { $0.peripheral == peripheral }) {
            peripherals.remove(at: index)
        }
        connectedPeripherals.remove(peripheral)
        characteristics.removeValue(forKey: peripheral)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            if let localName = peripherals.first(where: { $0.peripheral == peripheral })?.localName {
                print("发现外围设备的服务: \(localName)")
            }
            for service in services {
                print("发现服务的特征值: \(service.uuid)")
                if service.uuid == serviceUUID {
                    peripheral.discoverCharacteristics([characteristicUUID], for: service)
                }
            }
        } else {
            if let localName = peripherals.first(where: { $0.peripheral == peripheral })?.localName {
                print("发现服务失败: \(localName), 错误: \(error?.localizedDescription ?? "未知错误")")
            }
        }
    }

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
                    print("读取特征值: \(characteristic.uuid)")
                }
                if characteristic.properties.contains(.notify) {
                    peripheral.setNotifyValue(true, for: characteristic)
                    print("设置特征值通知: \(characteristic.uuid)")
                }
            }
        } else {
            if let localName = peripherals.first(where: { $0.peripheral == peripheral })?.localName {
                print("发现特征值失败: \(service.uuid) 在外围设备: \(localName), 错误: \(error?.localizedDescription ?? "未知错误")")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value {
            if let localName = peripherals.first(where: { $0.peripheral == peripheral })?.localName {
                print("收到数据来自 \(localName), uuid: \(characteristic.uuid), data: \(data)")
            }
        } else {
            if let localName = peripherals.first(where: { $0.peripheral == peripheral })?.localName {
                print("读取特征值失败: \(characteristic.uuid) 在外围设备: \(localName), 错误: \(error?.localizedDescription ?? "未知错误")")
            }
        }
    }

    
    func writeValueToAll(_ data: Data) {
        if connectedPeripherals.isEmpty{
            return
        }
         //isSending = true
          let dispatchGroup = DispatchGroup()
          let queue = DispatchQueue(label: "com.ble.writeQueue", attributes: .concurrent)

          for peripheral in connectedPeripherals {
              if let characteristics = self.characteristics[peripheral] {
                  for characteristic in characteristics {
                      if characteristic.uuid == characteristicUUID {
                          let workItem = DispatchWorkItem {
                              self.writeValue(data, for: characteristic, on: peripheral)
                              dispatchGroup.leave()
                          }
                          sendWorkItems.append(workItem)
                          dispatchGroup.enter()
                          queue.async(execute: workItem)
                      }
                  }
              }
          }

          dispatchGroup.notify(queue: .main) {
             // self.isSending = false
              print("所有数据写入完成")
          }
    }
 
    func writeValue(_ data: Data, for characteristic: CBCharacteristic, on peripheral: CBPeripheral) {
        peripheral.writeValue(data, for: characteristic, type: .withResponse)
 
    }

    func disconnectAll() {
        stopSending()
        for peripheral in connectedPeripherals {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        connectedPeripherals.removeAll()
        peripherals.removeAll()
        characteristics.removeAll()
        print("断开所有连接")
    }
    
    func stopSending() {
        isSending = false

        for workItem in sendWorkItems {
            workItem.cancel()
        }
        sendWorkItems.removeAll()
        print("已停止所有发送任务")
    }

    
    func sendColorAndSpeed(_ color:Color,_ isEnabled:Bool=true,_ isSpeedEnabled:Bool = false,speed:Double) {
        let colorData = ColorUtil.toRGBUInt8(color: color)
        let data = ColorUtil.buildColorData(
            red: colorData.red,
            green: colorData.green,
            blue: colorData.blue,
            isEnabled: isEnabled,
            isSpeedEnabled: isSpeedEnabled,
            speed: speed
        )
        writeValueToAll(data)
    }
    
    func sendColorIntAndSpeed(_ red:UInt8,_ green:UInt8,_ blue:UInt8,_ isEnabled:Bool=true,_ isSpeedEnabled:Bool = false,speed:Double) {
        let data = ColorUtil.buildColorData(
            red: red,
            green: green,
            blue: blue,
            isEnabled: isEnabled,
            isSpeedEnabled: isSpeedEnabled,
            speed: speed
        )
        writeValueToAll(data)
    }
    
    
    func toggleScanning() {
        isScanning ? 
        stopScanning() :
        {
            characteristics = characteristics.filter { connectedPeripherals.contains($0.key) }
            startScanning()
        }()
    }
    func stopTimer() {
        scanTimer?.invalidate()
        scanTimer = nil
    }

    private func startTimer() {
        scanTimer?.invalidate()
        scanTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            self.centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
}
