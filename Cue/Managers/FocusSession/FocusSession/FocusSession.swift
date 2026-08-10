//
//  FocusSession.swift
//  VaneUI
//
//  Created by Krishna Venkatramani on 20/06/2026.
//

import Foundation


@MainActor
protocol FocusSessionControl: AnyObject {
    func onCompletion()
}

@MainActor
protocol FocusSession {
    var startTime: Date? { get set }
    var endTime: Date? { get }
    var alarmID: UUID? { get set }
    var liveActivityID: UUID? { get set }
    var currentSessionIndex: Int { get set }
    var control: FocusSessionControl? { get set }
    var state: FocusSessionState { get set }
    var timerProgress: Double { get }
    var timerDuration: TimeInterval { get set }
    var breakDuration: TimeInterval { get set }
    var currentTimerDuration: TimeInterval { get }
    var totalDuration: TimeInterval { get }
    func startTimer()
    func resetTimer()
    func resumeTimer()
    func pauseTimer()
}

extension FocusSession {
    
    var endTime: Date? {
        nil
    }
    
    var currentTimerDuration: TimeInterval {
        timerDuration
    }
    
    var totalDuration: TimeInterval {
        timerDuration
    }
    
    var startTime: Date? {
        get{ nil }
        set { }
    }
    
    var alarmID: UUID? {
        get { nil }
        set { }
    }
    
    var liveActivityID: UUID? {
        get { nil }
        set { }
    }
}
