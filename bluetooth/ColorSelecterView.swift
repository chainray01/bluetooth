import SwiftUI
import CoreBluetooth

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
           .padding(.top,10)

            if selectedView == 0 {
                ColorGridView(selectedColor: $selectedColor)
                .padding() // 增加内边距避免内容贴边
            } else {
                ColorSlidersView(selectedColor: $selectedColor)
                    .padding() // 增加内边距避免内容贴边
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top) // 使视图靠近上部
        .background(Color.gray.opacity(0.1)) // 添加背景颜色，以便区别内容区域
        .padding()
    }
}

struct ColorGridView: View {
   // var onColorSelected: (Color) -> Void
    @Binding var selectedColor: Color
    let colors: [[Color]] = {
        var colors = [[Color]]()
        for hue in stride(from: 0.1, to: 1.0, by: 0.1) {
            var rowColors = [Color]()
            for saturation in stride(from: 0.1, to: 1.0, by: 0.1) {
                rowColors.append(Color(hue: hue, saturation: saturation, brightness: 1.0))
            }
            colors.append(rowColors)
        }
        let fksj =  [ColorUtil.argbToColor(argb: "#FF3F6C7D"),ColorUtil.argbToColor(argb: "#FF4AC9E3"),ColorUtil.argbToColor(argb: "#FF0092BD")];
        colors.append(fksj)
      
    
        return colors
    }()

    var body: some View {
        GeometryReader { geometry in
            VStack {
                //Spacer().frame(height: 0) // 添加距离顶部的空间
                VStack(spacing: 3) {
                    ForEach(0..<colors.count, id: \.self) { row in
                        HStack(spacing: 3) {
                            ForEach(0..<colors[row].count, id: \.self) { col in
                                colors[row][col]
                                    .onTapGesture {
                                        selectedColor = colors[row][col]
                                    }
                                    .frame(width: min(geometry.size.width / 10 , 35), height: min(geometry.size.height / 10 , 35)) // 自适应大小
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ColorSlidersView: View {
    @Binding var selectedColor: Color
    @State private var hue: Double = 0.5
    @State private var saturation: Double = 0.5
    @State private var brightness: Double = 0.5

    var body: some View {
        VStack(spacing: 20) {
            Slider(value: $hue, in: 0...1)
                .accentColor(Color.init(hue: hue, saturation: saturation, brightness: brightness))
                
            Text("色相: \(hue, specifier: "%.2f")")

            Slider(value: $saturation, in: 0...1)
                .accentColor(Color.green).saturation(saturation)
            Text("饱和度: \(saturation, specifier: "%.2f")")

            Slider(value: $brightness, in: 0...1)
                .accentColor(.blue).brightness(brightness > 0.4 ? 0.4 : brightness)
            Text("亮度: \(brightness, specifier: "%.2f")")
            

        }
        .onChange(of: hue) { _ in updateColor() }
        .onChange(of: saturation) { _ in updateColor() }
        .onChange(of: brightness) { _ in updateColor() }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .padding()

    }

    private func updateColor() {
        selectedColor = Color(hue: hue, saturation: saturation, brightness: brightness)
    }
}
 

 
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        ColorSelecterView(selectedColor: .constant(Color.white))
    }
}
