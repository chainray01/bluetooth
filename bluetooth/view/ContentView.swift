//
//  ContentView.swift
//  bluetooth
//
//  Created by Ray chai on 2024/5/28.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @ObservedObject var bleManager = BLEManager.shared
    var body: some View {
        TabView{
//            DiscoverView().tabItem {
//                let cnt = bleManager.connectedPeripherals.count
//                Label("discover(\( cnt >  0 ?cnt : 0))", systemImage: "list.bullet")
//            }
            DeviceView( ).tabItem {
                let cnt = bleManager.connectedPeripherals.count
                Label("device(\( cnt >  0 ?cnt : 0))", systemImage: "list.bullet")
            }
            FavoritesView( )
                .tabItem {
                    Label("Favorites", systemImage: "star")
                }
        }
       
        
    }

}
#Preview {
    ContentView()
}
