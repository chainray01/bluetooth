//
//  HomeView.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/8.
//

import SwiftUI
import CoreBluetooth
struct HomeView: View {
    @ObservedObject var bleManager = BLEManager.shared
    var body: some View {
 
            // 使用嵌套的TabView和List来实现垂直排列的列表
            TabView {
                       // 使用嵌套的List来实现垂直排列的列表
                       List {
                           ForEach(Array(bleManager.connectedPeripherals), id: \.identifier) { peripheral in
                                   VStack {
                                       if let localName = bleManager.peripherals.first(where: { $0.peripheral == peripheral })?.localName {
                                           Text("设备: \(localName)")
                                       }
                                       if let characteristics = bleManager.characteristics[peripheral] {
                                           ForEach(characteristics, id: \.uuid) { characteristic in
                                               Text("特征值: \(characteristic.uuid)")
                                           }
                                       }
                                }
                           }
                           .listStyle(PlainListStyle())
                       }

                   }
            //
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
         
    }
}
 


#Preview {
    HomeView( )
}
