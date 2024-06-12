//
//  ColorSlidersView.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/11.
//

import SwiftUI

/// 颜色滑块视图，允许用户通过滑块调整颜色
struct ColorSlidersView: View {
    @Binding var selectedColor: Color
    @State private var hue: Double = 0.5
    @State private var saturation: Double = 0.5
    @State private var brightness: Double = 0.5

    var body: some View {
        VStack(spacing: 5) {
            HStack{
                Slider(value: $hue, in: 0...1)
                    .accentColor(Color(hue: hue, saturation: saturation, brightness: brightness))
                Text("H: \(hue, specifier: "%.2f")").foregroundStyle(Color.blue)
            }
            HStack{
                Slider(value: $saturation, in: 0...1)
                    .accentColor(Color.green).saturation(saturation)
                Text("S: \(saturation, specifier: "%.2f")").foregroundStyle(Color.blue)
            }
            HStack{
                Slider(value: $brightness, in: 0...1)
                    .accentColor(.blue).brightness(brightness > 0.4 ? 0.4 : brightness)
                Text("L: \(brightness, specifier: "%.2f")").foregroundStyle(Color.blue)
            }
            let fksj = ColorUtil.argbToColor(argb: "#FF3F6C7D")
            let aqws = ColorUtil.argbToColor(argb: "#FF4AC9E3")
            let rshh = ColorUtil.argbToColor(argb: "#FF0092BD")

            HStack(spacing: 20) {
                VStack {
                    Circle()
                        .fill(selectedColor)
                        .frame(width: 50, height: 50)
                        .onTapGesture {
                            selectedColor = selectedColor
                            updateSliders(with: selectedColor)
                        }
                    Text("HSL颜色").font(.caption)
                       // .padding(5)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(5).foregroundColor(fksj)
                }
                VStack {
                    Circle()
                        .fill(fksj)
                        .frame(width: 50, height: 50)
                        .onTapGesture {
                            selectedColor = fksj
                            updateSliders(with: fksj)
                        }
                    Text("疯狂世界").font(.caption)
                       // .padding(5)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(5).foregroundColor(fksj)
                }
                VStack {
                    Circle()
                        .fill(aqws)
                        .frame(width: 50, height: 50)
                        .onTapGesture {
                            selectedColor = aqws
                            updateSliders(with: aqws)
                        }
                    Text("爱情万岁").font(.caption)
                       // .padding(5)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(5).foregroundColor(aqws)
                }
                VStack {
                    Circle()
                        .fill(rshh)
                        .frame(width: 50, height: 50)
                        .onTapGesture {
                            selectedColor = rshh
                            updateSliders(with: rshh)
                        }
                    Text("人生海海")  .font(.caption)
                       // .padding(5)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(5).foregroundColor(rshh)
                }
            }
            .padding(.top, 10)
            
            GeometryReader { geometry in
                DeviceGroupView(selectedColor: $selectedColor )
                    .frame(width: geometry.size.width) // 自适应宽度并保持边距
                    //.padding(.horizontal, 20)
                   
            }
        }
        
        .onChange(of: hue) { _ in    DispatchQueue.main.async {
            updateColor()
        } }
        .onChange(of: saturation) { _ in    DispatchQueue.main.async {
            updateColor()
        } }
        .onChange(of: brightness) { _ in    DispatchQueue.main.async {
            updateColor()
        } }
      //  .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 10)
//                .fill(Color.white)
//                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
//        )
       // .padding()
    }

    /// 更新选定颜色
    private func updateColor() {
        selectedColor = Color(hue: hue, saturation: saturation, brightness: brightness)
    }

    /// 根据颜色更新滑块值
    private func updateSliders(with color: Color) {
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        #if os(iOS)
        UIColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        #elseif os(macOS)
        NSColor(color).getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        #endif

        hue = Double(h)
        saturation = Double(s)
        brightness = Double(b)
    }
}

struct ColorSlidersView_Previews: PreviewProvider {
    static var previews: some View {
        ColorSlidersView(selectedColor: .constant(Color.white))
    }
}
