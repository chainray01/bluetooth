//
//  WriteDataUtil.swift
//  bluetooth
//
//  Created by Ray Chai on 2024/6/13.
//

import CoreBluetooth

final class WriteDataUtil {
    
    static let shared = WriteDataUtil()
    
    var bleManager = BLEManager.shared
    private var sendQueue = DispatchQueue(label: "com.ble.sendQueue", attributes: .concurrent)
    private var sendWorkItems: [DispatchWorkItem] = []
    private var stopSendFlag = false
    
    func stopSending() {
        stopSendFlag = true
        sendQueue.suspend()
        sendWorkItems.forEach { $0.cancel() }
        sendWorkItems.removeAll()
        sendQueue.resume()
    }
    
    func writeValueToAll(_ data: Data) {
        guard !bleManager.connectedPeripherals.isEmpty else { return }
        
        stopSendFlag = false
        let dispatchGroup = DispatchGroup()
        
        bleManager.connectedPeripherals.forEach { peripheral in
            guard let characteristics = bleManager.characteristics[peripheral],
                  let characteristic = characteristics.first(where: { $0.uuid == Constants.characteristicUUID }) else { return }
            
            dispatchGroup.enter()
            let workItem = DispatchWorkItem { [weak self] in
                guard let self = self, !self.stopSendFlag else {
                    dispatchGroup.leave()
                    return
                }
                
                self.bleManager.writeValue(data, for: characteristic, on: peripheral)
                
                if self.stopSendFlag {
                    dispatchGroup.leave()
                    return
                }
                
                dispatchGroup.leave()
            }
            
            self.sendWorkItems.append(workItem)
            self.sendQueue.async(execute: workItem)
        }
        
        notifyCompletion(for: dispatchGroup)
    }
    
    private func notifyCompletion(for dispatchGroup: DispatchGroup) {
        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            // UI updates or other main thread tasks go here
        }
    }
    
    func writeValueTo(_ data: Data, devices: [CBPeripheral]) {
        // Implement the logic for writing data to specific devices if needed
    }
    
    func disconnectAll() {
        stopSending()
        bleManager.connectedPeripherals.forEach { peripheral in
            bleManager.disconnect(peripheral: peripheral)
        }
        print("Disconnected all peripherals")
    }
}

