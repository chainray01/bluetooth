import SwiftUI

struct DiscoverView: View {
    @ObservedObject var bleManager = BLEManager.shared

    var body: some View {
        VStack {
            HStack {
                Text("BLE Devices")
                    .font(.largeTitle)
                    .padding(.leading)
                Spacer()
                Button(action: {
                    bleManager.toggleScanning()
                }) {
                    Text(bleManager.isScanning ? "停止扫描" : "开始扫描")
                        .padding(.trailing)
                }
            }
            .padding(.top)

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
                   // .background(Color(nsColor: NSColor.windowBackgroundColor)) // 自适应系统背景颜色
                    .cornerRadius(10)
                    .shadow(color: Color.gray.opacity(0.5), radius: 5, x: 0, y: 2)
                }
                .listRowBackground(Color.clear) // 设置行背景为透明
                .padding(.vertical, 5)
            }
            .listStyle(PlainListStyle())
            .background(Color.clear) // 设置列表背景为透明
             
        }
        .padding(.bottom, 25) // 加下边距以避免与TabView重叠
    }

 }

#Preview {
    DiscoverView()
}
