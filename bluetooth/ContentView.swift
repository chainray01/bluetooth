//
//  ContentView.swift
//  bluetooth
//
//  Created by Ray chai on 2024/5/28.
//

import SwiftUI
import CoreBluetooth

struct ContentView: View {
    var body: some View {
        TabView{
            DiscoverView().tabItem {
                Label("discover", systemImage: "list.bullet")
            }
            HomeView( ).tabItem {
                Label("device", systemImage: "list.bullet")
            }
            FavoritesView( )
                .tabItem {
                    Label("Favorites", systemImage: "star")
                }
        }
        
    }

}
#Preview {
    ContentView( )
}
