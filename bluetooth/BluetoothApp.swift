//
//  bluetoothApp.swift
//  bluetooth
//
//  Created by Ray chai on 2024/5/28.
//

import SwiftUI


@main
struct BluetoothApp: App {
    @Environment(\.scenePhase) private var scenePhase
   
    var body: some Scene {
        WindowGroup {
            ContentView()
        }.onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .active:
                print("应用程序处于活动状态")
            case .inactive:
                print("应用程序处于非活动状态") 
            case .background:
                print("应用程序进入后台")
                // 在这里执行任何需要的清理操作，例如保存数据或释放资源
            @unknown default:
                break
            }
        }
    }
}
 
