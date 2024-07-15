//
//  ColorSelecterView.swift
//  bluetooth
//
//  Created by Ray chai on 2024/5/28.
//
import SwiftUI

/// 颜色选择视图，包含网格视图和滑块视图
struct ColorSelecterView: View {
    @State private var selectedView: Int = 0
    @Binding var selectedColor: Color
 
    
    var body: some View {
        VStack {
            Picker("View Selection", selection: $selectedView) {
                Text("Grid").tag(0)
                Text("HSL").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.bottom,15)

            GeometryReader { geometry in
                switch selectedView {
                case 0:
                    ColorGridView(selectedColor: $selectedColor)
                        .frame(width: geometry.size.width, height: geometry.size.width) 
                        .animation(.easeInOut,value: selectedView) // 添加渐变动画效果
                case 1:
                    ColorSlidersView(selectedColor: $selectedColor)
                        .frame(width: geometry.size.width, height: geometry.size.width) 
                 
                        .animation(.easeInOut,value: selectedView) // 添加渐变动画效果
                default:
                    EmptyView()
                }
            }.padding(.top,10)
           
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // 使视图靠近上部
        .background(Color.gray.opacity(0.03)) // 添加背景颜色，以便区别内容区域
        .padding(.top,10)
       
    }
}

 
#Preview {
    ColorSelecterView(selectedColor: .constant(Color.white))
}
