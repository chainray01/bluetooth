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
            VStack {
                VStack(spacing: 3) {
                    ForEach(0..<colors.count, id: \.self) { row in
                        HStack(spacing: 3.5) {
                            ForEach(0..<colors[row].count, id: \.self) { col in
                                let color = colors[row][col]
                                color
                                    .scaleEffect(pressedColors[color] == true ? 0.9 : 1.0)
                                    .opacity(pressedColors[color] == true ? 0.7 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.5, blendDuration: 0.5), value: pressedColors[color])
                                    .onTapGesture {
                                        selectedColor = color
                                        generateHapticFeedback()
                                        withAnimation {
                                            pressedColors[color] = true
                                        }
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            withAnimation {
                                                pressedColors[color] = false
                                            }
                                        }
                                    }
                                    .frame(width: min(geometry.size.width / 10, 35), height: min(geometry.size.height / 5, 35))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
            }
        }
    }

    private func generateHapticFeedback() {
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #elseif os(macOS)
        let hapticManager = NSHapticFeedbackManager.defaultPerformer
        hapticManager.perform(.alignment, performanceTime: .default)
        #endif
    }
}

 

 
struct ColorGridView_Previews: PreviewProvider {
    static var previews: some View {
        ColorGridView(selectedColor: .constant(Color.white))
    }
}

 
