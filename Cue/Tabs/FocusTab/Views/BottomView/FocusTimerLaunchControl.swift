//
//  FocusTimerLaunchControl.swift
//  Cue
//
//  Created by Krishna Venkatramani on 30/04/2026.
//

import SwiftUI
import VanorUI

protocol TimerAdjustmentManager: AnyObject, Observable {
    var timerDuration: TimeInterval { get set }
    var maxBound: TimeInterval { get }
    var minBound: TimeInterval { get }
    var step: TimeInterval { get }
    
    func increment()
    func decrement()
}

extension TimerAdjustmentManager {
    func increment() {
        timerDuration = min(maxBound, timerDuration + step)
    }
    
    func decrement() {
        timerDuration = max(minBound, timerDuration - step)
    }
}

extension FocusSessionCoordinator: TimerAdjustmentManager {
    static let hourMark: TimeInterval = 3_600
    /// First 12 steps is the first hour , the rest step is 1 hour each.
    static let firstHourInFraction: CGFloat = 12 / 35
    static let fractionPerStep: CGFloat = 1 / 35
    
    // NOTE: intentionally `internal` — FTQuickStartView builds FTLaunchControlView.Model
    // from another file and needs to read this.
    var timerDurationAsString: String {
        timerDuration.timerDurationString
    }
    
    var step: TimeInterval {
        if timerDuration < Self.hourMark {
            return 5 * 60
        } else {
            return 60 * 60
        }
    }
    
    var minBound: TimeInterval {
        #if DEBUG
        return 1 * 60
        #else
        return 5 * 60
        #endif
    }
    
    var maxBound: TimeInterval {
        return 24 * 60 * 60
    }
    
    var startingDurationForSlider: CGFloat {
        if timerDuration < Self.hourMark {
            let factor = self.timerDuration / (5 * 60)
            print("(DEBUG) factor: ", factor)
            return factor / 35
        } else {
            let hour = timerDuration / Self.hourMark
            return Self.firstHourInFraction + (hour / 23)
        }
    }
    
    func sliderFractionToTimeDuration(fraction: CGFloat) {
        let stepForFraction = (fraction / Self.fractionPerStep).rounded(.toNearestOrAwayFromZero)
        if fraction < Self.firstHourInFraction {
            timerDuration = max(1 * 60, stepForFraction * 5 * 60)
        } else {
            timerDuration = (stepForFraction - 11) * 60 * 60
        }
    }
    
    
    // MARK: - Pomodoro Sessio Related Helpers
    
    var pomodoroSessionDurationString: String {
        timerDuration.timerDurationString
    }
    
    var pomodoroBreakDurationString: String {
        breakDuration.timerDurationString
    }
    
    var pomodoroSessionDescription: String {
        "\(pomodoroSessionDurationString) • \(pomodoroBreakDurationString) • \(pomodoroSessionCount) sessions"
    }
}
