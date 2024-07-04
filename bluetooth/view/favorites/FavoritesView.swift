//
//  FavoritesView.swift
//  bluetooth
//
//  Created by Ray Chai on 2024/5/28.
//

import Combine
import SwiftUI

struct FavoritesView: View {
  @State private var isSpeedEnabled = false
  @State private var isEnabled = true
  @State private var selectedColor = ColorUtil.argbToColor(argb: "#FF0092BD")
  @State private var isMonitoring = false
  @State private var selectedSpeed: Double = 10.0
  @State private var isGroupEnabled = false
  @ObservedObject var bleManager = BLEManager.shared
  @ObservedObject var audioMonitor = AudioMonitor.shared
  @State private var cancellables = Set<AnyCancellable>()
  var writeUtil = WriteDataUtil.shared

  // Delay handling related variables
  @State private var lastColorChangeTime = Date()
  private let handleInterval: Double = 0.02  // 20 ms

  var body: some View {
    VStack {
      Spacer()
      VStack {
        HStack(spacing: 20) {
          Toggle("启用", isOn: $isEnabled)
            .onChange(of: isEnabled) { newValue in
              handleEnable(newValue)
            }
          Toggle("闪灯", isOn: $isSpeedEnabled)
            .onChange(of: isSpeedEnabled) { _ in
              handleColorChange(selectedColor)
            }
          Toggle("分组", isOn: $isGroupEnabled)
            .onChange(of: isGroupEnabled) { _ in
              handleColorChange(selectedColor)
            }
//          Toggle("律动", isOn: $isMonitoring)
//            .onChange(of: isMonitoring) { newValue in
//              handleMonitoring(newValue)
//            }
        }
        .padding(.horizontal)
        .padding(.top, 5)

        HStack {
          Slider(value: $selectedSpeed, in: 0...Constants.maxSpeed, step: 1)
            .accentColor(Color.blue)
            .disabled(!isSpeedEnabled)
            .onChange(of: selectedSpeed) { _ in
              handleSpeedChange(selectedColor)
            }
            .frame(minWidth: 0, maxWidth: .infinity)
          Text("速度 \(String(format: "%.0f", selectedSpeed))")
            .frame(width: 60, alignment: .leading)
        }
        .padding(15)
      }
      .background(Color.gray.opacity(0.03))
      ColorSelecterView(selectedColor: $selectedColor)
    }
    .onChange(of: selectedColor) { newColor in
      handleColorChange(newColor)
    }
    .padding()
  }

  func handleSpeedChange(_ selectColor: Color) {
    sendColorData(selectColor)
  }

  func handleColorChange(_ selectColor: Color) {
    let currentTime = Date()
    let timeInterval = currentTime.timeIntervalSince(lastColorChangeTime)
    if timeInterval < handleInterval {
      return
    }
    lastColorChangeTime = currentTime
    if isEnabled {
      sendColorData(selectColor)
    }
  }

  func handleEnable(_ enabled: Bool) {
    if enabled {
      sendColorData(selectedColor)
    } else {
      Task {
        writeUtil.stopSending()
        let data = ColorUtil.buildTurnOff()
        writeUtil.writeValueToAll(data)
      }
    }
  }

  func handleMonitoring(_ monitoring: Bool) {
    if monitoring {
      audioMonitor.startMonitoring()
      audioMonitor.objectWillChange.sink { _ in
          let rawAudioData = audioMonitor.audioData
                          let denoisedAudioData = ColorUtil.denoiseAudio(data: rawAudioData)
                          let frequencyBands = ColorUtil.performFFT(data: denoisedAudioData)
                          let smoothedBands = ColorUtil.movingAverage(values: frequencyBands, windowSize: 5)
                          let (lowFrequency, highFrequency) = ColorUtil.processFrequencyBands(frequencyBands: smoothedBands)

                          let newHue = ColorUtil.mapFrequencyToHue(lowFrequency: lowFrequency, highFrequency: highFrequency)
                          let newBrightness = ColorUtil.mapAmplitudeToBrightness(amplitude: highFrequency)
                          
                          print("New Hue: \(newHue), New Brightness: \(newBrightness)")

                          selectedColor = Color(hue: newHue, saturation: 0.5, brightness: newBrightness)
                          isSpeedEnabled = ColorUtil.shouldFlashBasedOnAmplitude(amplitude: highFrequency)
                          
                          handleColorChange(selectedColor) // Update color with new hue and flashing state
      }.store(in: &cancellables)
    } else {
      audioMonitor.stopMonitoring()
      cancellables.removeAll()
    }
  }

  private func sendColorData(_ color: Color) {
    Task {
      let data = ColorUtil.buildColor(color, isEnabled, isSpeedEnabled, selectedSpeed)
      writeUtil.writeValueToAll(data)
    }
  }
}

struct FavoritesView_Previews: PreviewProvider {
  static var previews: some View {
    FavoritesView()
  }
}
