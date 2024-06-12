//
//  LightDataService.swift
//  bluetooth
//
//  Created by Ray chai on 2024/6/12.
//

import Foundation

struct LightPreset {
    var time: Int // 毫秒
    var color: String
}

class LightDataService {
    var currentTimeMillisecond: Int = 0
    var isTimerRunning: Bool = false
    var manualMode: Bool = false
    var presetAllTimeSecond: Int = 0
    var preset: [LightPreset]? = nil
    var lightData: [Int: String] = [:]
    var tweenedLightData: [Int: String] = [:]
    var hasStarted: Bool = false

    func clearState() {
        currentTimeMillisecond = 0
        isTimerRunning = false
        manualMode = false
        presetAllTimeSecond = 0
        preset = nil
        lightData = [:]
        tweenedLightData = [:]
        hasStarted = false
    }

    func setCurrentTimeMillisecond(_ time: Int) {
        currentTimeMillisecond = time
    }

    func addMillisecond(_ time: Int) -> Int {
        currentTimeMillisecond += time
        return currentTimeMillisecond
    }

    func setIsTimerRunning(_ isRunning: Bool) {
        isTimerRunning = isRunning
    }

    func setManualMode(_ manual: Bool) {
        manualMode = manual
    }

    func setPresetAllTimeSecond(_ time: Int) {
        presetAllTimeSecond = time
    }

    func setPreset(_ preset: [LightPreset]) {
        self.preset = preset
    }

    func setLightData(_ data: [Int: String]) {
        lightData = data
    }

    func setHasStarted(_ started: Bool) {
        hasStarted = started
    }

    func generateTweenedLightData() {
        guard let preset = preset else { return }

        var timePoints = preset.map { $0.time }
        var lightDict = [Int: String]()
        
        // Ensure starting point at 0ms
        if timePoints.first != 0 {
            timePoints.insert(0, at: 0)
            lightDict[0] = "off4"
        }
        
        // Ensure ending point at total time
        let totalTime = presetAllTimeSecond * 1000
        if timePoints.last != totalTime {
            timePoints.append(totalTime)
            lightDict[totalTime] = "off4"
        }
        
        // Fill lightDict with preset values
        for point in preset {
            lightDict[point.time] = point.color
        }
        
        // Generate tweened light data
        for (index, time) in timePoints.enumerated() {
            tweenedLightData[time] = lightDict[time]
            
            if index < timePoints.count - 1 {
                let nextTime = timePoints[index + 1]
                for t in stride(from: time + 200, to: nextTime, by: 200) {
                    tweenedLightData[t] = lightDict[time]
                }
            }
        }
    }



}

func test(){
    let presets = [
        LightPreset(time: 0, color: "red"),
        LightPreset(time: 1000, color: "blue"),
        LightPreset(time: 3000, color: "green")
    ]

    let service = LightDataService()
    service.setPreset(presets)
    service.setPresetAllTimeSecond(5) // 设置总时间为5秒
    service.generateTweenedLightData()

    print(service.tweenedLightData)
}
