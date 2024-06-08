//
//  FavoritesView.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/8.
//

import SwiftUI
import CoreBluetooth
struct FavoritesView: View {
    @State private var selectedColor = Color.red
    @State private var selectedSpeed:Double = 0.1
    @ObservedObject var bleManager = BLEManager.shared
    var body: some View {
        VStack {

            ColorPicker("选择颜色", selection: $selectedColor)
                .onChange(of: selectedColor) {
                    newValue in
                    
                        sendColorAndSpeed()
                    }
                      
                }
                .padding()
            // Slider for speed selection
            Slider(value: $selectedSpeed, in: 0.1...50, step: 0.1)
                .onChange (of: selectedSpeed) { newSpeed in
                      sendColorAndSpeed()
                }
                .padding()
            Text("Selected speed: \( selectedSpeed)")
                .padding()
            .pickerStyle(SegmentedPickerStyle())
            .padding()
        }
    }
    
    func sendColorAndSpeed() {
        let colorData =  ColorUtil.toRGBUInt8(color:selectedColor)
        let speedData = selectedSpeed
        let data = ColorUtil.buildColorData(red: colorData.red,green: colorData.green,blue: colorData.blue, speed: speedData)
        bleManager.writeValueToAll(data)
    }
}

struct FavoritesView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesView( )
    }
}
