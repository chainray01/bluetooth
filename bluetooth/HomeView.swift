import SwiftUI
import CoreBluetooth

struct HomeView: View {
    @ObservedObject var bleManager = BLEManager.shared

    var body: some View {
        NavigationView{
            TabView {
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
                }
                .listStyle(PlainListStyle())
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .navigationTitle("Bluetooth Devices")
        }}
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
