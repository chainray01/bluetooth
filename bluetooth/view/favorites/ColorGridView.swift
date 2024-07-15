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
        for hue in stride(from: 0, to: 1.0, by: 0.1) {
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
            .padding() // Add padding around the grid
            .background(Color.clear) // Ensure gesture area covers the entire view
            .contentShape(Rectangle()) // Expand hit test area
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
        guard !colors.isEmpty, !colors[0].isEmpty else {
            return nil
        }

        let cellWidth = (size.width - CGFloat(colors[0].count - 1) * 3) / CGFloat(colors[0].count)
        let cellHeight = (size.height - CGFloat(colors.count - 1) * 3) / CGFloat(colors.count)

        guard cellWidth > 0, cellHeight > 0 else {
            return nil
        }

        guard location.x >= 0, location.y >= 0 else {
            return nil
        }

        let col = Int((location.x - 10) / (cellWidth + 3))
        let row = Int((location.y - 10) / (cellHeight + 3))

        guard row >= 0, row < colors.count, col >= 0, col < colors[row].count else {
            return nil
        }

        return colors[row][col]
    }
}
 
#Preview {
    ColorGridView(selectedColor: .constant(Color.white))
}
