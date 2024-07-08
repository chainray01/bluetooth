//
//  ColorUtil.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/8.
//

import AVFoundation
import Accelerate
import Combine
import CoreBluetooth
import SwiftUI

struct ColorUtil {

  //颜色转rbg分量
  static func toRGBUInt8(color: Color) -> (red: UInt8, green: UInt8, blue: UInt8) {
    let components = color.cgColor?.components
    let red = components?[0] ?? 0
    let green = components?[1] ?? 0
    let blue = components?[2] ?? 0
    return (UInt8(red * 255), UInt8(green * 255), UInt8(blue * 255))
  }

  /// 颜色数据转荧光棒字节数组
  /// - Parameters:
  ///   - red: red
  ///   - green: green
  ///   - blue: blue
  ///   - isEnabled: 是否点亮
  ///   - isSpeedEnabled: 是否闪烁
  ///   - speed: 闪烁速度
  /// - Returns: [170, 161, 0, 146, 189, 255, 255, 20]
  static func buildColorData(
    _ red: UInt8, _ green: UInt8, _ blue: UInt8, _ isEnabled: Bool = true,
    _ isSpeedEnabled: Bool = false, _ speed: Double
  ) -> Data {

    // Set the "enabled" and "speed" flags true255 /false0
    let enabledFlag: UInt8 = isEnabled ? 255 : 0
    let speedFlag: UInt8 = isSpeedEnabled ? 255 : 0

    // Create an 8-byte array to hold the command data
    var commandData = Data(count: 8)

    // Set the fixed command header 170 161
    commandData[0] = 0xAA
    commandData[1] = 0xA1

    // Set the RGB values
    commandData[2] = red
    commandData[3] = green
    commandData[4] = blue

    // Set the "enabled" and "speed" flags
    commandData[5] = enabledFlag
    commandData[6] = speedFlag

    // Set the calculated speed value
    commandData[7] = UInt8(Constants.maxSpeed - speed)
    // Return the prepared Data
    return commandData
  }

  static func argbToColor(argb: String) -> Color {
    // 清理字符串并转换为大写
    var cleanedArgbString = argb.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    // 移除前缀 #
    if cleanedArgbString.hasPrefix("#") {
      cleanedArgbString.remove(at: cleanedArgbString.startIndex)
    }
    // 将字符串转换为数字
    var argbValue: UInt64 = 0
    Scanner(string: cleanedArgbString).scanHexInt64(&argbValue)

    // 解析颜色分量
    let alpha = CGFloat((argbValue & 0xFF00_0000) >> 24) / 255.0
    let red = CGFloat((argbValue & 0x00FF_0000) >> 16) / 255.0
    let green = CGFloat((argbValue & 0x0000_FF00) >> 8) / 255.0
    let blue = CGFloat(argbValue & 0x0000_00FF) / 255.0
    return Color(cgColor: .init(srgbRed: red, green: green, blue: blue, alpha: alpha))
  }

  /// 构建灯光数据
  /// - Parameters:
  ///   - color: 颜色
  ///   - isEnabled: 是否启用
  ///   - isSpeedEnabled: 启用速度
  ///   - speed: 速度
  /// - Returns: data
  static func buildColor(
    _ color: Color, _ isEnabled: Bool = true, _ isSpeedEnabled: Bool = false, _ speed: Double) -> Data {
    let data = toRGBUInt8(color: color)
    return buildColorData(data.red, data.green, data.blue, isEnabled, isSpeedEnabled, speed)
  }

  static func buildTurnOff() -> Data {
    return buildColor(ColorUtil.argbToColor(argb: "#FF0092BD"), false, true, 1)
  }

  static func performFFT(data: [Float]) -> [Float] {
    guard !data.isEmpty else {
      return []
    }

    let log2n = UInt(round(log2(Double(data.count))))
    let fftSetup = vDSP_create_fftsetup(log2n, Int32(kFFTRadix2))

    let n = data.count
    var realp = [Float](repeating: 0, count: n / 2)
    var imagp = [Float](repeating: 0, count: n / 2)
    var splitComplex = DSPSplitComplex(realp: &realp, imagp: &imagp)

    data.withUnsafeBufferPointer { pointer in
      pointer.baseAddress!.withMemoryRebound(to: DSPComplex.self, capacity: n) {
        typeConvertedTransferBuffer in
        vDSP_ctoz(typeConvertedTransferBuffer, 2, &splitComplex, 1, vDSP_Length(n / 2))
      }
    }

    vDSP_fft_zrip(fftSetup!, &splitComplex, 1, vDSP_Length(log2n), FFTDirection(FFT_FORWARD))

    var magnitudes = [Float](repeating: 0, count: n / 2)
    vDSP_zvmags(&splitComplex, 1, &magnitudes, 1, vDSP_Length(n / 2))

    let normalizedMagnitudes = magnitudes.map { sqrt($0) }

    vDSP_destroy_fftsetup(fftSetup)

    // Debugging: Print or plot FFT magnitudes
    //  print("FFT Magnitudes: \(normalizedMagnitudes)")

    return normalizedMagnitudes
  }

  static func movingAverage(values: [Float], windowSize: Int) -> [Float] {
    var result = [Float](repeating: 0.0, count: values.count)
    vDSP_vsma(
      values, 1, [1.0 / Float(windowSize)], values, 1, &result, 1, vDSP_Length(values.count))
    return result
  }

  static func processFrequencyBands(frequencyBands: [Float]) -> (Float, Float) {
      let sampleRate = 44100 // Adjust based on your actual sample rate
             let lowFrequencyThreshold = sampleRate / 8 // Adjust to include more frequencies
             let highFrequencyThreshold = sampleRate / 2 // Keep up to half of the sample rate

             let lowFrequencyRange = 0..<lowFrequencyThreshold
             let highFrequencyRange = lowFrequencyThreshold..<highFrequencyThreshold

             let lowFrequencyMagnitudes = frequencyBands.indices.filter {
                 $0 * sampleRate / frequencyBands.count >= lowFrequencyRange.lowerBound &&
                 $0 * sampleRate / frequencyBands.count < lowFrequencyRange.upperBound
             }.map { frequencyBands[$0] }

             let highFrequencyMagnitudes = frequencyBands.indices.filter {
                 $0 * sampleRate / frequencyBands.count >= highFrequencyRange.lowerBound &&
                 $0 * sampleRate / frequencyBands.count < highFrequencyRange.upperBound
             }.map { frequencyBands[$0] }

             let lowFrequency = safeAverage(lowFrequencyMagnitudes)
             let highFrequency = safeAverage(highFrequencyMagnitudes)

             return (lowFrequency, highFrequency)
  }

  static func mapFrequencyToHue(lowFrequency: Float, highFrequency: Float) -> Double {
    // Increase sensitivity with a scaling factor
    let hue = Double((lowFrequency + highFrequency) / 2 * 2).truncatingRemainder(dividingBy: 1.0)
    return hue.isNaN ? 0.0 : hue
  }

  static func mapAmplitudeToBrightness(amplitude: Float) -> Double {
    // Increase sensitivity with a scaling factor
    let brightness = Double(amplitude * 2).clamped(to: 0...1)
    return brightness.isNaN ? 0.0 : brightness
  }

  static func shouldFlashBasedOnAmplitude(amplitude: Float) -> Bool {
      return amplitude > 0.7
  }
  static func denoiseAudio(data: [Float]) -> [Float] {
    // Simple noise gate algorithm
    let threshold: Float = 0.01  // Adjust this threshold as needed
    return data.map { abs($0) < threshold ? 0 : $0 }
  }
  static func safeAverage(_ values: [Float]) -> Float {
    guard !values.isEmpty else {
      return 0
    }
    return values.reduce(0, +) / Float(values.count)
  }

}
extension Comparable {
  func clamped(to limits: ClosedRange<Self>) -> Self {
    return min(max(self, limits.lowerBound), limits.upperBound)
  }
}
