import SwiftUI

struct DiscoverView: View {
    @ObservedObject var bleManager = BLEManager.shared

    var body: some View {
          NavigationView {
              VStack {
                  List(bleManager.peripherals, id: \.peripheral.identifier) { item in
                      VStack(alignment: .leading) {
                          HStack {
                              VStack(alignment: .leading, spacing: 5) {
                                  Text(item.localName)
                                      .font(.headline)
                                      .foregroundColor(.primary)
                                  Text("信号强度 (RSSI): \(item.rssi)")
                                      .font(.subheadline)
                                      .foregroundColor(.secondary)
                              }
                              Spacer()
                              if bleManager.connectedPeripherals.contains(item.peripheral) {
                                  Text("已连接")
                                      .font(.caption)
                                      .padding(5)
                                      .background(Color.green.opacity(0.2))
                                      .cornerRadius(5)
                              }
                          }
                          .padding()
                          .background(Color.white)
                          .cornerRadius(10)
                          .shadow(color: Color.gray.opacity(0.5), radius: 5, x: 0, y: 2)
                      }
                      .padding(.vertical, 5)
                  }
                  .listStyle(PlainListStyle())
                  .padding(.horizontal)
                  .background(Color(UIColor.systemGroupedBackground))
              }
              .navigationTitle("BLE Devices")
              .padding(.bottom, 25) // Add padding to avoid overlap with TabView
          }
          .tabViewStyle(DefaultTabViewStyle())
      }
  }

#Preview {
    DiscoverView()
}
