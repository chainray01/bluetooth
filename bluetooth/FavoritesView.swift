import SwiftUI
import CoreBluetooth

struct FavoritesView: View {
    
    @State private var selectedSpeed: Double = 0.1
    @ObservedObject var bleManager = BLEManager.shared
    @State private var red: Double = 0
    @State private var green: Double = 211
    @State private var blue: Double = 173
    @State private var isSpeedEnabled = false
    @State private var isEnabled = true
    @State private var selectedColor = Color.red 
    
    
    var body: some View {
        VStack(spacing: 10) {  // 减少 VStack 的 spacing
            HStack {
                Toggle("启用", isOn: $isEnabled)
                    .onChange(of: isEnabled) { newValue in
                        handleEnable(newValue)
                    }
                    .padding(.horizontal)
                
                Toggle("闪灯", isOn: $isSpeedEnabled)
                    .onChange(of: isSpeedEnabled) { newValue in
                        handleFlashing(newValue)
                    }
                    .padding(.horizontal)
            }
            .padding(.top, 20) // 增加一点顶部填充
            ColorSelecterView(selectedColor: $selectedColor)
        }.onChange(of: selectedColor) { newColor in
           
           handleColorChange(selectedColor)
        }
        .padding()
        .navigationTitle("颜色混合")
    }


    func handleColorChange(_ selectColor: Color) {
        bleManager.sendColorAndSpeed(selectColor, speed: selectedSpeed)
    }
    func handleFlashing(_ isFlashing: Bool) {
        bleManager.sendColorIntAndSpeed(UInt8(red), UInt8(green), UInt8(blue), speed: selectedSpeed)
    }

    func handleEnable(_ isEnabled: Bool) {
        bleManager.sendColorIntAndSpeed(UInt8(red), UInt8(green), UInt8(blue), speed: selectedSpeed)
    }


}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
    }
}
