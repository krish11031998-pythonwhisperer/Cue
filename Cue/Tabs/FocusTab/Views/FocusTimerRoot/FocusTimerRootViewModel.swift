//
//  FocusTimerRootViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 21/06/2026.
//

import Foundation
import Model
import VanorUI
import SwiftUI

@MainActor
@Observable
class FocusTimerRootViewModel {
    
    static let translationsXThreshold: CGFloat = 100
    
    enum Sheet: Identifiable {
        case pomodoroSessionEditor
        
        var id: String {
            switch self {
            case .pomodoroSessionEditor:
                return "pomodoroSessionEditor"
            }
        }
    }
    
    enum TimerType: Identifiable, Equatable {
        case focus
        case reminder(ReminderModel)
        
        var id: String {
            switch self {
            case .focus:
                return "focus"
            case .reminder(let reminderModel):
                return "reminder_\(reminderModel.title)"
            }
        }
        
        var icon: Icon {
            switch self {
            case .focus:
                return .symbol(.timer)
            case .reminder(let reminderModel):
                return .init(reminderModel.icon)!
            }
        }
        
        var theme: LCHColor {
            switch self {
            case .focus:
                return Color.proSky
            case .reminder(let reminderModel):
                return .init(color: reminderModel.color)
            }
        }
        
        var title: String {
            switch self {
            case .focus:
                return "Focus"
            case .reminder(let reminderModel):
                return reminderModel.title
            }
        }
    }
    
    var sheetPresentation: Sheet?
    var timerItems: [TimerType] = [.focus]
    var selectedTimerItem: TimerType = .focus
    @ObservationIgnored
    var currentSelectedReminderIdx: Int = 0
    var panGestureTranslation: CGFloat = 0
    

    init(reminders: [ReminderModel]) {
        self.selectedTimerItem = .focus
        self.timerItems = [.focus] + reminders.map { .reminder($0) }
    }
    
    convenience init() {
        self.init(reminders: [])
    }
    
    
    func updateSelectedReminder(forwards: Bool, backwards: Bool) {
        if forwards && currentSelectedReminderIdx < timerItems.count - 1 {
            currentSelectedReminderIdx += 1
        } else if backwards && currentSelectedReminderIdx > 0 {
            currentSelectedReminderIdx -= 1
        } else {
            withAnimation(.snappy) {
                self.panGestureTranslation = 0
            }
        }
        
        self.selectedTimerItem = timerItems[currentSelectedReminderIdx]
    }
    
    func updateWithReminders(_ reminders: [ReminderModel]) {
        var newUpdatedItems: [TimerType] = [.focus]
        reminders.forEach { reminder in
            newUpdatedItems.append(.reminder(reminder))
        }
        self.timerItems = newUpdatedItems
    }
    
    func presentAction(sessionType: FocusTimerType) {
        switch sessionType {
        case .classic:
            // Do nothing for now
            break
        case .pomodoro:
            sheetPresentation = .pomodoroSessionEditor
        }
    }
}
