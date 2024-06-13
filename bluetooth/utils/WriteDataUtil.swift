//
//  WriteDataUtil.swift
//  bluetooth
//
//  Created by Ray Chai on 2024/6/13.
//

import Foundation

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
        print("Stopped all sending tasks")
    }
    
    func writeValueToAll(_ data: Data) {
        guard !bleManager.connectedPeripherals.isEmpty else { return }
        
        stopSendFlag = false
        let dispatchGroup = DispatchGroup()
        
        for peripheral in bleManager.connectedPeripherals {
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
                    
                    self.bleManager.writeValue(data, for: characteristic, on: peripheral)
                    dispatchGroup.leave()
                }
                
                self.sendWorkItems.append(workItem)
                self.sendQueue.async(execute: workItem)
            }
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            print("stopSendFlag: \(self.stopSendFlag)")
            // UI updates or other main thread tasks go here
        }
    }
    
    func disconnectAll() {
        stopSending()
        let data = ColorUtil.buildTurnOff() // Assuming ColorUtil is another utility class
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
