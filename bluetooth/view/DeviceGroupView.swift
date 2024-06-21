//
//  DeviceGroupView.swift
//  bluetooth
// 设备分组视图，允许用户选择设备分组并为其选择颜色
//  Created by Ray chai on 2024/6/12.
//

import SwiftUI
import CoreBluetooth

struct DeviceGroupView: View {
    @State private var selectedColors: [Color] = []
    @State private var showingColorGrid = false

      var body: some View {
          VStack {
              // 展示已选颜色
              SelectedColorsView(selectedColors: $selectedColors)
              
              // 添加颜色按钮
              Button("Add Color") {
                  showingColorGrid = true
              }
              .sheet(isPresented: $showingColorGrid) {
                  // 初始颜色为白色，或者你可以根据需要设置为其他颜色
              }
          }
      }
  }

struct SelectedColorsView: View {
    @Binding var selectedColors: [Color]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(selectedColors.indices, id: \.self) { index in
                    selectedColors[index]
                        .frame(width: 50, height: 50)
                        .border(Color.black, width: 1)
                }
            }
        }
    }
}

#Preview {
    DeviceGroupView()
}
