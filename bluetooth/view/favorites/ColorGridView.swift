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

    let colors: [[Color]] = {
        var colors = [[Color]]()
        for hue in stride(from: 0.1, to: 1.0, by: 0.1) {
            var rowColors = [Color]()
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
                                .scaleEffect(pressedColors[color] == true ? 0.9 : 1.0)
                                .opacity(pressedColors[color] == true ? 0.7 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.5), value: pressedColors[color])
                                .onTapGesture {
                                    selectColor(color)
                                }
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding(.horizontal)
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
        let cellWidth = (size.width - CGFloat(colors[0].count - 1) * 3) / CGFloat(colors[0].count)
        let cellHeight = (size.height - CGFloat(colors.count - 1) * 3) / CGFloat(colors.count)

        let col = Int(location.x / (cellWidth + 3))
        let row = Int(location.y / (cellHeight + 3))

        guard row >= 0 && row < colors.count && col >= 0 && col < colors[row].count else {
            return nil
        }

        return colors[row][col]
    }

 
}

struct ColorGridView_Previews: PreviewProvider {
    static var previews: some View {
        ColorGridView(selectedColor: .constant(Color.white))
    }
}
