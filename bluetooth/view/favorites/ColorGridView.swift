//
//  ColorGridView.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/11.
//

import SwiftUI

struct ColorGridView: View {
    @Binding var selectedColor: Color
    @State private var pressedColors: [Color: Bool] = [:]
    @State private var dragLocation: CGPoint = .zero
  //  var onSelect: (Color) -> Void
    
    let colors: [[Color]] = {
        var colors = [[Color]]()
        for hue in stride(from: 0, to: 1.0, by: 0.1) {
            var rowColors = [Color]()
            //饱和度为0 都是白色
            for saturation in stride(from: 0.1, to: 1.0, by: 0.1) {
                rowColors.append(Color(hue: hue, saturation: saturation, brightness: 1.0))
            }
            colors.append(rowColors)
        }
        return colors
    }()

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 3) {
                ForEach(0..<colors.count, id: \.self) { row in
                    HStack(spacing: 3) {
                        ForEach(0..<colors[row].count, id: \.self) { col in
                            let color = colors[row][col]
                            color
                                .scaleEffect(pressedColors[color] == true ? 0.5 : 1.0)
                                .opacity(pressedColors[color] == true ? 0.5 : 1.0)
                                .animation(.spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0.5), value: pressedColors[color])
                                .onTapGesture {
                                    selectColor(color)
                                }
                                .clipShape(Circle())
                        }
                    }
                }
            }
           // .padding(.horizontal)
            .background(Color.clear) // 确保手势覆盖整个区域
            .contentShape(Rectangle()) // 扩展点击和拖动区域
            .gesture(DragGesture()
                .onChanged { value in
                    dragLocation = value.location
                    if let selectedColor = getColorAtLocation(dragLocation, in: geometry.size) {
                        selectColor(selectedColor)
                    }
                }
            )
        }
    }

    private func selectColor(_ color: Color) {
        selectedColor = color
        //onSelect(color)
        withAnimation {
            pressedColors[color] = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation {
                pressedColors[color] = false
            }
        }
    }

    private func getColorAtLocation(_ location: CGPoint, in size: CGSize) -> Color? {
        // 检查 colors 数组是否为空或者包含空行
        guard !colors.isEmpty, !colors[0].isEmpty else {
            return nil
        }

        // 计算每个单元格的宽度，减去列间的间隙总宽度后除以列数
        let cellWidth = (size.width - CGFloat(colors[0].count - 1) * 3) / CGFloat(colors[0].count)
        
        // 计算每个单元格的高度，减去行间的间隙总高度后除以行数
        let cellHeight = (size.height - CGFloat(colors.count - 1) * 3) / CGFloat(colors.count)

        // 防止除以零的情况
        guard cellWidth > 0, cellHeight > 0 else {
            return nil
        }

        // 如果 location 的 x 或 y 坐标为负数，返回 nil
        guard location.x >= 0, location.y >= 0 else {
            return nil
        }

        // 根据 location 的 x 坐标和单元格宽度加上间隙的和来确定列索引
        let col = Int(location.x / (cellWidth + 3))
        
        // 根据 location 的 y 坐标和单元格高度加上间隙的和来确定行索引
        let row = Int(location.y / (cellHeight + 3))

        // 检查计算出的行和列索引是否在 colors 数组的有效范围内
        guard row >= 0, row < colors.count, col >= 0, col < colors[row].count else {
            return nil // 如果索引超出范围，返回 nil
        }

        // 返回指定行和列的颜色
        return colors[row][col]
    }



 
}

struct ColorGridView_Previews: PreviewProvider {
    static var previews: some View {
        ColorGridView(selectedColor: .constant(Color.white))
     }
}
