
//
//  FavoritesView.swift
//  bluetooth
//
//  Created by Ray chai on 2024/5/28.
//
import SwiftUI
import CoreBluetooth

struct FavoritesView: View {
    @State private var isSpeedEnabled = false
    @State private var isEnabled = true
    @State private var selectedColor = ColorUtil.argbToColor(argb: "#FF0092BD")
    @State private var selectedSpeed: Double = 10.0
    @State private var isGroupEnabled = false
    @ObservedObject var bleManager = BLEManager.shared
    
    
    var body: some View {
        VStack(spacing: 5) {  // 减少 VStack 的 spacing
            HStack(spacing: 20) {
                  Toggle("启用", isOn: $isEnabled)
                      .onChange(of: isEnabled) { newValue in
                          handleEnable(isEnabled, selectedColor)
                      }
                  
                  Toggle("闪灯", isOn: $isSpeedEnabled)
                      .onChange(of: isSpeedEnabled) { newValue in
                          handleColorChange(selectedColor)
                      }
                  
                  Toggle("分组", isOn: $isGroupEnabled) // Adjusted based on your requirement
                      .onChange(of: isGroupEnabled) { newValue in
                          handleColorChange(selectedColor)
                      }
              }
              .padding(.horizontal)
              .padding(.top, 5) // 增加一点顶部填充
        
                HStack{
                    Slider(value:  $selectedSpeed, in: 0...15,step: 1)
                        .accentColor(Color.blue).saturation(selectedSpeed/16)
                        .disabled(!isSpeedEnabled) // 根据 isSpeedEnabled 控制 Slider 的可用状态
                        .onChange(of: selectedSpeed)
                    { newColor in
                        DispatchQueue.main.async {
                            handleColorChange(selectedColor)
                        }
                    }
                    Text("速度\(selectedSpeed, specifier: "%.0f")")}
                .padding(.top,10)
            ColorSelecterView(selectedColor: $selectedColor,isGroupEnabled:  $isGroupEnabled)
        }.onChange(of: selectedColor) { newColor in
           handleColorChange(selectedColor)
        }
      .padding()
       
    }


    func handleColorChange(_ selectColor: Color) {
 
        let data = ColorUtil.buildLightData(selectColor,isEnabled,isSpeedEnabled, speed: selectedSpeed)
        bleManager.writeValueToAll(data)
    }
    func handleFlashing(_ selectColor: Color) {
      }

    func handleEnable(_ bool: Bool,_ selectColor: Color) {
        bleManager.stopSending()
        let data =  ColorUtil.buildLightData(selectColor,isEnabled,isSpeedEnabled, speed: selectedSpeed)
        bleManager.writeValueToAll(data)
    }

}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
    }
}
