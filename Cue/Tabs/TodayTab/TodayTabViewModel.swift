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

/// Bumped whenever `TodayViewModel.refreshLogs()` patches the logs of the loaded days in place.
/// Only `CalendarDayView` reads it, so logging never invalidates `TodayTabView` — a re-render there
/// makes `PageView` replace the visible page with a freshly built one.
@Observable
final class CalendarDayLogsRevision {
    fileprivate(set) var value: Int = 0
}

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
    let logsRevision: CalendarDayLogsRevision = .init()
    @ObservationIgnored
    private var calendarParsingTask: Task<Void, Never>?
    @ObservationIgnored
    private var logsRefreshTask: Task<Void, Never>?
    
    
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
    
    /// Logging only changes a day's logs, never which reminders it has, so rather than replacing
    /// `calendarDay` the fresh logs are written into the existing `CalendarDay` instances. `PageView`
    /// holds those same instances, so pages built later (swiping) read the fresh logs too.
    func refreshLogs() {
        logsRefreshTask?.cancel()
        logsRefreshTask = Task { [weak self] in
            let freshDays = await CalendarManager.shared.setupCalendarForOneMonthFromToday()
            
            guard !Task.isCancelled, !freshDays.isEmpty else { return }
            
            await MainActor.run { [weak self] in
                guard let self else { return }
                let freshDaysByDate = Dictionary(freshDays.map { ($0.date, $0) }, uniquingKeysWith: { first, _ in first })
                for day in self.calendarDay {
                    guard let freshDay = freshDaysByDate[day.date] else { continue }
                    day.loggedReminders = freshDay.loggedReminders
                    day.loggedReminderTasks = freshDay.loggedReminderTasks
                }
                self.logsRevision.value += 1
            }
        }
    }
    
    func reminderForTimerWithTasks(_ reminder: ReminderModel?) -> Set<ReminderTaskModel> {
        guard let reminder, let todayInCalendar else { return [] }
        let loggedTasks = todayInCalendar.loggedReminderTasks
        return Set(reminder.tasks).intersection(Set(loggedTasks))
    }
}
