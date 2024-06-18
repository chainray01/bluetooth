//
//  WriteDataUtil.swift
//  bluetooth
//
//  Created by Ray Chai on 2024/6/13.
//

import Foundation
import CoreBluetooth
class WriteDataUtil {
    static let shared = WriteDataUtil()
    
    var bleManager = BLEManager.shared
    private var sendQueue = DispatchQueue(label: "com.ble.sendQueue", attributes: .concurrent)
    private var sendWorkItems: [DispatchWorkItem] = []
    private var stopSendFlag = false
    
    func stopSending() {
        stopSendFlag = true
        sendQueue.suspend()
        for workItem in sendWorkItems {
            workItem.cancel()
        }
        sendWorkItems.removeAll()
        sendQueue.resume()
    }
    
    func writeValueToAll(_ data: Data) {
        guard !bleManager.connectedPeripherals.isEmpty else { return }
        
        stopSendFlag = false
        let dispatchGroup = DispatchGroup()
        
        bleManager.connectedPeripherals.forEach { peripheral in
            if let characteristics = bleManager.characteristics[peripheral],
               let characteristic = characteristics.first(where: { $0.uuid == bleManager.characteristicUUID }) {
                
                dispatchGroup.enter()
                let workItem = DispatchWorkItem { [weak self] in
                    guard let self = self else {
                        dispatchGroup.leave()
                        return
                    }
                    
                    if self.stopSendFlag {
                        dispatchGroup.leave()
                        return
                    }
                    
                    bleManager.writeValue(data, for: characteristic, on: peripheral)
                    // 再次检查 stopSendFlag，以便在长时间操作后响应停止信号
                     if self.stopSendFlag {
                         dispatchGroup.leave()
                         return // 提前退出
                     }
                    
                    dispatchGroup.leave()
                }
                
                self.sendWorkItems.append(workItem)
                self.sendQueue.async(execute: workItem)
            }
        }
        
        notifyCompletion(for: dispatchGroup)
    }
    
    private func notifyCompletion(for dispatchGroup: DispatchGroup) {
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
          //  print("stopSendFlag: \(self.stopSendFlag)")
          
            // UI updates or other main thread tasks go here
        }
    }
    
    func writeValueTo(_ data: Data,devices:[CBPeripheral]) {
        
    }
    
    
    func disconnectAll() {
        stopSending()
        let data = ColorUtil.buildTurnOff()
        writeValueToAll(data)
        
        for peripheral in bleManager.connectedPeripherals {
            bleManager.centralManager.cancelPeripheralConnection(peripheral)
        }
        
        bleManager.connectedPeripherals.removeAll()
        bleManager.peripherals.removeAll()
        bleManager.characteristics.removeAll()
        
        print("Disconnected all peripherals")
    }
}
