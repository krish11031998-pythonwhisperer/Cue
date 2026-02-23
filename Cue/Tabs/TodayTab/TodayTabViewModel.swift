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
    
    enum Presentation: String, Identifiable {
        case timer
        
        var id: String { rawValue }
    }
    
    enum FullScreenPresentation: Identifiable {
        case calendar
        case focusTimer(ReminderModel?, Set<ReminderTaskModel>, TimeInterval)
        
        var id: Int {
            switch self {
            case .calendar:
                return 0
            case .focusTimer:
                return 1
            }
        }
    }
    
    var calendarDay: [CalendarDay] = []
    var loggedReminders: [Reminder] = []
    var today: Date = Date.now.startOfDay
    var todayCalendar: CalendarDay? = nil
    var presentation: Presentation? = nil
    var fullPresentation: FullScreenPresentation? = nil
    @ObservationIgnored
    private var calendarParsingTask: Task<Void, Never>?
    
    
    var todayInCalendar: CalendarDay? {
        calendarDay.first(where: { $0.date == today })
    }
    
    var reminderWithTimer: [ReminderModel] {
        guard let todayCalendar else { return []}
        
        return todayCalendar.reminders
            .filter({ reminder in
                return !todayCalendar.loggedReminders.contains(where: { reminder.objectId == $0.reminder.objectId })
            })
    }
    
    func setupCalendarForOneMonth(reminders: [Reminder]) {
        print(#function)
        guard !reminders.isEmpty else { return }
        calendarParsingTask?.cancel()
        calendarParsingTask = Task { [weak self] in
            let calendarValues = await CalendarManager.shared.setupCalendarForOneMonthFromToday()
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run { [weak self] in
                guard calendarValues.isEmpty == false else { return }
                let today = calendarValues.first {
                    return $0.date == Date.now.startOfDay
                }
                
                self?.todayCalendar = today
                
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
