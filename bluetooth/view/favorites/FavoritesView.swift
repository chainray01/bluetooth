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
        VStack {
            Spacer()
            VStack{
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
                //.padding(.top, 5)
                
                HStack {
                    Slider(value: $selectedSpeed, in: 0 ... Constants.maxSpeed, step: 1)
                        .accentColor(Color.blue)
                        .disabled(!isSpeedEnabled)
                        .onChange(of: selectedSpeed) { newSpeed in
                            handleColorChange(selectedColor)
                        }
                        .frame(minWidth: 0, maxWidth: .infinity) // 确保 Slider 占据尽可能多的空间
                    Text("速度 \(String(format: "%.0f", selectedSpeed))")
                        .frame(width: 60, alignment: .leading) // 固定宽度以确保布局稳定
                }
                .padding(15)
            }
            .background(Color.gray.opacity(0.03)) // 添加背景颜色，以便区别内容区域
            ColorSelecterView(selectedColor: $selectedColor)
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
        
            lastColorChangeTime = currentTime
            if isEnabled {
                Task{
                    let data = ColorUtil.buildColor(selectColor, isEnabled, isSpeedEnabled, speed: selectedSpeed)
                    writeUtil.writeValueToAll(data)
                }
            }
         
    }
    
    func handleEnable(_ enabled: Bool, _ selectColor: Color) {
        if enabled {
            Task{ 
                    let data = ColorUtil.buildColor(selectColor, isEnabled, isSpeedEnabled, speed: selectedSpeed)
                    writeUtil.writeValueToAll(data)
            }
        } else {
            Task{
                writeUtil.stopSending()
                let data = ColorUtil.buildTurnOff()
                writeUtil.writeValueToAll(data)
            }
        }
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView()
    }
}
