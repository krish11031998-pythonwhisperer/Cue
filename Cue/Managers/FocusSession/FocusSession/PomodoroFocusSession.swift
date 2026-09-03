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
    
    var currentClassicSessionIndex: Int = 0
    
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
        sessions.first?.startTime
    }
    
    var endTime: Date? {
        sessions.last?.endTime
    }
    
    private(set) var pausedAt: Date?
    @ObservationIgnored
    private var accumalatedRestTime: TimeInterval = 0
    @ObservationIgnored
    var alarmID: UUID?
    @ObservationIgnored
    var liveActivityID: UUID?
    
    var allAlarmIDs: [UUID] = []
    
    private var sessions: [ClassicFocusSession] = []
    
    init(sessionCount: Int, singleSessionDuration: TimeInterval, breakSessionDuration: TimeInterval) {
        self.timerDuration = singleSessionDuration
        self.breakDuration = breakSessionDuration
        
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
        updateStartDatesForOtherSession()
    }
    
    func resetTimer() {
        // Reset Timer
        currentSession.resetTimer()
        #warning("Test without this: Too see if you need this")
        onCompletion()
    }
    
    func resumeTimer() {
        if let pausedAt {
            self.accumalatedRestTime += Date.now.timeIntervalSince(pausedAt)
            updateStartDatesForOtherSession()
            self.pausedAt = nil
        }
        // Resume Timer
        currentSession.resumeTimer()
    }
    
    func pauseTimer() {
        self.pausedAt = Date()
        // Pause Timer
        currentSession.pauseTimer()
    }

    
    // MARK: - SessionManagment
    
    private func updateStartDatesForOtherSession() {
        guard currentSessionIndex < sessionCount - 1,
              var startTime else { return }
        
        startTime = startTime.addingTimeInterval(currentSession.timerDuration + accumalatedRestTime)
        for idx in currentSessionIndex + 1..<sessionCount {
            let session = sessions[idx]
            session.startTime = startTime
            startTime.addTimeInterval(session.timerDuration)
            print("(DEBUG) #\(idx) \(session.self).startTime: \(String(describing: session.startTime))")
        }
    }
    
    // MARK: - FocusSessionControl
    
    func onCompletion() {
        currentSession.resetTimer()
        guard currentSessionIndex < sessionCount - 1 else {
            self.control?.onCompletion()
            return
        }
        if !(currentSession is BreakFocusSession) {
            currentClassicSessionIndex += 1
        }
        currentSessionIndex += 1
        accumalatedRestTime = 0
        currentSession.startTimer()
    }
    
}
