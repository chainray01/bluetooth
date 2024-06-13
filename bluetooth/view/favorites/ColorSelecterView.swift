//
//  ColorSelecterView.swift
//  bluetooth
//
//  Created by Ray chai on 2024/5/28.
//
import SwiftUI
import CoreBluetooth

/// 颜色选择视图，包含网格视图和滑块视图
struct ColorSelecterView: View {
    @State private var selectedView: Int = 0
    @Binding var selectedColor: Color

    var body: some View {
        VStack {
            Picker("View Selection", selection: $selectedView) {
                Text("Grid").tag(0)
                Text("Sliders").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.top, 10)

            GeometryReader { geometry in
                VStack {
                    if selectedView == 0 {
                        ColorGridView(selectedColor: $selectedColor)
                          //  .frame(width: geometry.size.width, height: geometry.size.width) // 设置宽高比为1:1
                            .padding() // 增加内边距避免内容贴边
                    } else {
                        ColorSlidersView(selectedColor: $selectedColor)
                            //.frame(width: geometry.size.width, height: geometry.size.width) // 设置宽高比为1:1
                            .padding() // 增加内边距避免内容贴边
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // 使视图靠近上部
        .background(Color.gray.opacity(0.03)) // 添加背景颜色，以便区别内容区域
        .padding()
    }
}

struct ColorSelecterView_Previews: PreviewProvider {
    static var previews: some View {
        ColorSelecterView(selectedColor: .constant(Color.white))
    }
}
