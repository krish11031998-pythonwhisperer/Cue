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
    func updateForNextSession()
}

@MainActor
protocol FocusSession: AnyObject, Observable {
    var startTime: Date? { get }
    var endTime: Date? { get }
    /// Start / end of the session currently running. A Classic session is a single
    /// session, so these span the whole run; a Pomodoro's are its work and break sessions.
    var currentSessionStartTime: Date? { get }
    var currentSessionEndTime: Date? { get }
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
    
    var currentSessionStartTime: Date? {
        startTime
    }
    
    var currentSessionEndTime: Date? {
        endTime
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
