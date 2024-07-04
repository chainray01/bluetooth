//
//  AudioMonitor.swift
//  bluetooth
//
//  Created by Ray chai on 2024/7/3.
//

import AVFoundation
import Accelerate
import Combine
import CoreBluetooth
import SwiftUI

class AudioMonitor: NSObject, ObservableObject, AVAudioRecorderDelegate {
  @Published var amplitude: Float = 0.0
  @Published var audioData: [Float] = []

  private var audioRecorder: AVAudioRecorder!
  private var timer: Timer?
  static let shared = AudioMonitor()
  private override init() {
    super.init()
    setupRecorder()
    print("初始化音频管理器")
  }

  private func setupRecorder() {
    let audioSession = AVAudioSession.sharedInstance()

    do {
      try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
      try audioSession.setActive(true)

      let settings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
      ]

      let url = URL(fileURLWithPath: "/dev/null")
      audioRecorder = try AVAudioRecorder(url: url, settings: settings)
      audioRecorder.isMeteringEnabled = true
      audioRecorder.delegate = self
    } catch {
      print("Failed to set up audio session and recorder: \(error)")
    }
  }

  func startMonitoring() {
    print("startMonitoring...")
    audioRecorder.record()
    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
      self.audioRecorder.updateMeters()
      self.amplitude = self.audioRecorder.averagePower(forChannel: 0)
      self.audioData = [Float](repeating: self.amplitude, count: 2048)
    }
  }

  func stopMonitoring() {
    audioRecorder.stop()
    timer?.invalidate()
    timer = nil
  }
}
