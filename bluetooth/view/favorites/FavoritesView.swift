//
//  FavoritesView.swift
//  bluetooth
//
//  Created by Ray Chai on 2024/5/28.
//

import SwiftUI

struct FavoritesView: View {
    @State private var isSpeedEnabled = false
    @State private var isEnabled = true
    @State private var selectedColor = ColorUtil.argbToColor(argb: "#FF0092BD")
    @State private var selectedSpeed: Double = 10.0
    @State private var isGroupEnabled = false
    @ObservedObject var bleManager = BLEManager.shared
    var writeUtil = WriteDataUtil.shared
    
    // 延时处理相关的变量
    @State private var lastColorChangeTime = Date()
    private let handleInterval: Double = 0.02 // 20 毫秒
    
    var body: some View {
        VStack(spacing: 5) {
            HStack(spacing: 20) {
                Toggle("启用", isOn: $isEnabled)
                    .onChange(of: isEnabled) { newValue in
                        handleEnable(isEnabled, selectedColor)
                    }
                
                Toggle("闪灯", isOn: $isSpeedEnabled)
                    .onChange(of: isSpeedEnabled) { newValue in
                        handleColorChange(selectedColor)
                    }
                
                Toggle("分组", isOn: $isGroupEnabled)
                    .onChange(of: isGroupEnabled) { newValue in
                        handleColorChange(selectedColor)
                    }
            }
            .padding(.horizontal)
            .padding(.top, 5)
            
            HStack {
                Slider(value: $selectedSpeed, in: 0...15, step: 1)
                    .accentColor(Color.blue)
                    .saturation(selectedSpeed / 16)
                    .disabled(!isSpeedEnabled)
                    .onChange(of: selectedSpeed) { newSpeed in
                        handleColorChange(selectedColor)
                    }
                Text("速度 \(selectedSpeed, specifier: "%.0f")")
            }
            .padding(.top, 10)
            
            ColorSelecterView(selectedColor: $selectedColor, isGroupEnabled: $isGroupEnabled)
        }
        .onChange(of: selectedColor) { newColor in
            handleColorChange(selectedColor)
        }
        .padding()
    }
    
      func handleColorChange(_ selectColor: Color) {
        let currentTime = Date()
        let timeInterval = currentTime.timeIntervalSince(lastColorChangeTime)
        //太快了数据量太大 会导致棒子响应迟滞
        if timeInterval >= 0.05 {
            lastColorChangeTime = currentTime
            let data = ColorUtil.buildLightData(selectColor, isEnabled, isSpeedEnabled, speed: selectedSpeed)
            if isEnabled {
                writeUtil.writeValueToAll(data)
            }
        }
    }
    
    func handleEnable(_ enabled: Bool, _ selectColor: Color) {
        if enabled {
            let data = ColorUtil.buildLightData(selectColor, isEnabled, isSpeedEnabled, speed: selectedSpeed)
            writeUtil.writeValueToAll(data)
        } else {
            writeUtil.stopSending()
            let data = ColorUtil.buildTurnOff()
            writeUtil.writeValueToAll(data)
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
    }
}
