import SwiftUI
import CoreBluetooth

struct FavoritesView: View {
//    @State private var red: UInt8 = 0
//    @State private var green: UInt8 = 211
//    @State private var blue: UInt8 = 173
    @State private var isSpeedEnabled = false
    @State private var isEnabled = true
    @State private var selectedColor = Color.orange
    @State private var selectedSpeed: Double = 10.0
    @ObservedObject var bleManager = BLEManager.shared
    
    
    var body: some View {
        VStack(spacing: 5) {  // 减少 VStack 的 spacing
            HStack {
                Toggle("启用", isOn: $isEnabled)
                    .onChange(of: isEnabled) { newValue in
                        handleColorChange( selectedColor)
                    }
                    .padding(.horizontal)
                
                Toggle("闪灯", isOn: $isSpeedEnabled)
                    .onChange(of: isSpeedEnabled) { newValue in
                        handleColorChange(selectedColor)
                    }
                    .padding(.horizontal)
            }
            .padding(.top, 5) // 增加一点顶部填充
            HStack{
                Slider(value:  $selectedSpeed, in: 0...15,step: 1).onChange(of: selectedSpeed)
                { newColor in
                    handleColorChange(selectedColor)
                }
                Text("速度\(selectedSpeed, specifier: "%.0f")")}
            .padding(.bottom,0).padding(.top,5)
            ColorSelecterView(selectedColor: $selectedColor).padding(.bottom,2)
        }.onChange(of: selectedColor) { newColor in
           handleColorChange(selectedColor)
        }
      .padding()
       // .navigationTitle("颜色混合")
    }


    func handleColorChange(_ selectColor: Color) {
    //  let data =  ColorUtil.toRGBUInt8(color: selectColor)
//        red = data.red
//        green = data.green
//        blue = data.blue
        bleManager.sendColorAndSpeed(selectColor,isEnabled,isSpeedEnabled, speed: selectedSpeed)
       // bleManager.sendColorAndSpeed(selectColor, speed: selectedSpeed)
    }
    func handleFlashing(_ selectColor: Color) {
     //   bleManager.sendColorAndSpeed(selectColor, isEnabled,isSpeedEnabled,speed: selectedSpeed)
    }

    func handleEnable(_ selectColor: Color) {
      //  bleManager.sendColorAndSpeed(selectColor,isEnabled,isSpeedEnabled, speed: selectedSpeed)
    }

}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
    }
}
