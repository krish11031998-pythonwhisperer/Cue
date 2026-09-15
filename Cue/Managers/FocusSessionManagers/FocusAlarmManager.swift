//
//  FocusAlarmManager.swift
//  Cue
//
//  Created by Krishna Venkatramani on 05/06/2026.
//

import Model
import VanorUI
import SwiftUI
internal import AlarmKit

class FocusAlarmManager: FocusTimerAlarmCoordinator {
    
    
    var alarmManager: CueAlarmManager?
      
    /// Schedules the session's alarm carrying the session's own attributes, so the alarm
    /// presents as the session it closes rather than as a generic timer.
    public func scheduleAlarmForTimer(startDate: Date, timeInterval: TimeInterval, sessionAttributes: FocusSessionAttributes) async -> (UUID, Alarm)? {
        guard let alarmManager else { return nil }
        return await alarmManager.scheduleAlarm(metadata: .init(sessionAttributes),
                                                startDate: startDate,
                                                timeDuration: timeInterval,
                                                tintColor: sessionAttributes.color.baseColor)
    }
    
    public func requestAuthorization() async -> Bool {
        guard let alarmManager else  { return false }
        switch alarmManager.authorizationState {
        case .notDetermined:
            await alarmManager.requestForAuthortization()
            return alarmManager.authorizationState == .authorized
        case .denied:
            return false
        case .authorized:
            return true
        @unknown default:
            return false
        }
    }
    
    public func cancelAlarm(_ uuid: UUID) {
        alarmManager?.cancelAlarms([uuid])
    }

    func authorizationStatus() async -> AlarmManager.AuthorizationState {
        return alarmManager?.authorizationState ?? .notDetermined
    }
}
