//
//  PomodoroFocusSession.swift
//  VaneUI
//
//  Created by Krishna Venkatramani on 20/06/2026.
//

import Foundation

internal class BreakFocusSession: ClassicFocusSession { }

@MainActor
@Observable
public class PomodoroFocusSession: FocusSession, FocusSessionControl {
    
    weak var control: FocusSessionControl? = nil
    
    var state: FocusSessionState {
        get {
            currentSession.state
        }
        
        set {
            sessions[currentSessionIndex].state = newValue
        }
    }
    
    var timerProgress: Double {
        // return .zero for now
        return currentSession.timerProgress
    }

    var currentSessionIndex: Int = 0
    
    var timerDuration: TimeInterval = 0.0
    
    var breakDuration: TimeInterval = 0.0
    
    private var sessionCount: Int {
        sessions.count
    }
    
    /// TimerDuration of the currently active session (Classic Or Break)
    var currentTimerDuration: TimeInterval {
        currentSession.timerDuration
    }
    
    var totalDuration: TimeInterval {
        sessions.reduce(0, { $0 + $1.timerDuration })
    }
    
    var startTime: Date? {
        get {
            sessions.first?.startTime
        }
        
        set {}
    }
    
    var alarmID: UUID?
    var liveActivityID: UUID?
    
    var allAlarmIDs: [UUID] = []
    
    private let singleSessionDuration: TimeInterval
    private let breakSessionDuration: TimeInterval
    private var sessions: [ClassicFocusSession] = []
    
    init(sessionCount: Int, singleSessionDuration: TimeInterval, breakSessionDuration: TimeInterval) {
        self.singleSessionDuration = singleSessionDuration
        self.breakSessionDuration = breakSessionDuration
        
        for i in 0..<sessionCount {
            let classicSession = ClassicFocusSession(timerDuration: singleSessionDuration)
            classicSession.control = self
            if i == sessionCount - 1 {
                sessions.append(classicSession)
            } else {
                let breakSession = BreakFocusSession(timerDuration: breakSessionDuration)
                breakSession.control = self
                sessions.append(classicSession)
                sessions.append(breakSession)
            }
        }
    }
    
    var currentSession: FocusSession {
        sessions[currentSessionIndex]
    }
    
    func startTimer() {
        // Start Timer
        currentSession.startTimer()
    }
    
    func resetTimer() {
        // Reset Timer
        currentSession.resetTimer()
        onCompletion()
    }
    
    func resumeTimer() {
        // Resume Timer
        currentSession.resumeTimer()
    }
    
    func pauseTimer() {
        // Pause Timer
        currentSession.pauseTimer()
    }

    
    // MARK: - FocusSessionControl
    
    func onCompletion() {
        currentSession.resetTimer()
        guard currentSessionIndex < sessionCount - 1 else {
            self.control?.onCompletion()
            return
        }
        currentSessionIndex += 1
        currentSession.startTimer()
    }
    
}
