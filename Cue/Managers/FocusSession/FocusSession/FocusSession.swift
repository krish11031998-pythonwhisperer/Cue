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
protocol FocusSession: AnyObject, Observable {
    var startTime: Date? { get }
    var endTime: Date? { get }
    var pausedAt: Date? { get }
    var alarmID: UUID? { get set }
    var liveActivityID: UUID? { get set }
    var currentSessionIndex: Int { get }
    var currentClassicSessionIndex: Int { get }
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
    
    var pausedAt: Date? {
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
}
