//
//  ClassicFocusSession.swift
//  VaneUI
//
//  Created by Krishna Venkatramani on 20/06/2026.
//
 
import Foundation

@MainActor
@Observable
class ClassicFocusSession: FocusSession, @MainActor Hashable {
    
    var currentSessionIndex: Int = 0
    weak var control: FocusSessionControl? = nil
    var state: FocusSessionState = .idle
    var startTime: Date? = nil
    var timerDuration: TimeInterval = 0.0
    var breakDuration: TimeInterval = 0.0
    var elapsedTimeBetweenPauses: TimeInterval = 0.0
    @ObservationIgnored
    var alarmID: UUID?
    @ObservationIgnored
    var liveActivityID: UUID?
    private var elapsedTime: TimeInterval = 0.0
    internal var onCompletion: (() -> Void)?
    
    var endTime: Date? {
        let distantFuture: TimeInterval = timerDuration
        return startTime?.addingTimeInterval(distantFuture)
    }
    
    @ObservationIgnored
    private var timer: Timer?
    @ObservationIgnored
    private var accumalatedRestTime: TimeInterval = 0
    
    var timerProgress: Double {
        elapsedTime / timerDuration
    }
    
    init(timerDuration: TimeInterval) {
        self.timerDuration = timerDuration
    }
    
    func startTimer() {
        let date = Date()
        self.startTime = date
        self.state = .start
        fireTimer()
    }
    
    func resetTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func pauseTimer() {
        self.state = .pause
        self.elapsedTimeBetweenPauses = self.elapsedTime
        self.startTime = nil
        self.timer?.invalidate()
        self.timer = nil
    }
    
    func resumeTimer() {
        self.state = .resume
        self.startTime = Date()
        self.fireTimer()
    }
    
    private var isOnResume: Bool {
        switch self.state {
        case .idle, .reset, .pause:
            return false
        case .start, .resume:
            return true
        }
    }
    
    private func fireTimer() {
        let timerDuration = timerDuration
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { timer in
            Task { @MainActor in
                
                guard let startTime = self.startTime else {
                    fatalError("Can't have a timer without startDate")
                }
                
                guard self.isOnResume else { return }
                let timeIntervalSinceStart = Date.now.timeIntervalSince(startTime)
                
                let progress = timeIntervalSinceStart + self.elapsedTimeBetweenPauses
                guard progress >= timerDuration else {
                    self.elapsedTime = Double(min(timerDuration, progress))
                    return
                }
                self.control?.onCompletion()
            }
        })
        timer?.fire()
    }
    
    static func == (lhs: ClassicFocusSession, rhs: ClassicFocusSession) -> Bool {
        return lhs.timerDuration == rhs.timerDuration && lhs.timerProgress == rhs.timerProgress && lhs.state == rhs.state
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(state)
        hasher.combine(timerProgress)
        hasher.combine(timerDuration)
    }
}
