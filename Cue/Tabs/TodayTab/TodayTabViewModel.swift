//
//  TodayTabViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 20/01/2026.
//

import Model
import VanorUI
import SwiftUI
import CoreData

@Observable
class TodayViewModel {
    
    enum FullScreenPresentation: Identifiable {
        case settings
        case focusTimer(ReminderModel?, Set<ReminderTaskModel>, TimeInterval)
        
        var id: Int {
            switch self {
            case .focusTimer:
                return 1
            case .settings:
                return 2
            }
        }
    }
    
    var calendarDay: [CalendarDay] = []
    var calendarDayModels: [CalendarDayView.Model] = []
    var loggedReminders: [Reminder] = []
    var today: Date = Date.now.startOfDay
    var fullPresentation: FullScreenPresentation? = nil
    @ObservationIgnored
    private var calendarParsingTask: Task<Void, Never>?
    
    
    var todayInCalendar: CalendarDay? {
        calendarDay.first(where: { $0.date == today })
    }
    
    var reminderWithTimer: [ReminderModel] {
        guard let todayInCalendar else { return []}
        
        return todayInCalendar.reminders
            .filter({ reminder in
                return !todayInCalendar.loggedReminders.contains(where: { reminder.objectId == $0.reminder.objectId })
            })
    }
    
    func setupCalendarForOneMonth(reminders: [ReminderModel]) {
        print(#function)
        guard !reminders.isEmpty else { return }
        calendarParsingTask?.cancel()
        calendarParsingTask = Task { [weak self] in
            let calendarValues = await CalendarManager.shared.setupCalendarForOneMonthFromToday()
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run { [weak self] in
                guard calendarValues.isEmpty == false else { return }

                self?.calendarDay = calendarValues
            }
            
        }
    }
    
    func reminderForTimerWithTasks(_ reminder: ReminderModel?) -> Set<ReminderTaskModel> {
        guard let reminder, let todayInCalendar else { return [] }
        let loggedTasks = todayInCalendar.loggedReminderTasks
        return Set(reminder.tasks).intersection(Set(loggedTasks))
    }
}
