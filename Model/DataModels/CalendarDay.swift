//
//  CalendarModel.swift
//  Model
//
//  Created by Krishna Venkatramani on 27/01/2026.
//

import Foundation


public class CalendarDay: Hashable, @unchecked Sendable {
    
    public var date: Date
    public var reminders: [ReminderModel] = []
    public var loggedReminders: [ReminderModel] = []
    
    public init(date: Date,
                reminders: [ReminderModel],
                loggedReminders: [ReminderModel]) {
        self.date = date
        self.loggedReminders = loggedReminders
        self.filterReminderForDate(reminders: reminders)
    }
    
    private func filterReminderForDate(reminders: [ReminderModel]) {
        self.reminders = reminders.filter { reminder in
            
            let startDate = reminder.date
            guard let schedule = reminder.schedule, date.startOfDay >= startDate.startOfDay else {
                return false
            }
            
            // WeekInterval
            if let intervalWeeks = schedule.intervalWeeks {
                guard let weekdays = schedule.weekdays,
                        checkIfDateIsInWeekInterval(startDate: startDate, intervalWeeks: intervalWeeks) else { return false }
                return checkIfDateInWeekdays(weekDays: weekdays)
            } else if let calendarDates = schedule.calendarDates {
                return calendarDates.contains(Calendar.current.component(.day, from: date))
            } else if date.startOfDay == startDate.startOfDay {
                return true
            }
            
            return false
        }
    }
    
//    private func filterReminderForDate(reminders: [Reminder]) {
//        var filteredReminders: [Reminder] = []
//        var filteredReminderLogs: [ReminderLog] = []
//         reminders.forEach { reminder in
//            
//            let startDate = reminder.date!
//            guard let schedule = reminder.schedule, date.startOfDay >= startDate.startOfDay else {
//                return
//            }
//            
//             var reminderToAppend: Reminder?
//            // WeekInterval
//            if let intervalWeeks = schedule.intervalWeeks {
//                guard let weekdays = schedule.weekdays,
//                        checkIfDateIsInWeekInterval(startDate: startDate, intervalWeeks: intervalWeeks),
//                        checkIfDateInWeekdays(weekDays: weekdays) else { return }
//                reminderToAppend = reminder
//            } else if let calendarDates = schedule.calendarDates, calendarDates.contains(Calendar.current.component(.day, from: date)) {
//                reminderToAppend = reminder
//            } else if date.startOfDay == startDate.startOfDay {
//                reminderToAppend = reminder
//            }
//             
//             if let reminderToAppend {
//                 filteredReminders.append(reminderToAppend)
//                 filteredReminderLogs = reminderToAppend.logs.filter {
//                     return $0.date >= date.startOfDay && $0.date <= date.endOfDay
//                 }
//             }
//        }
//        self.reminders = filteredReminders
//        self.reminderLogs = filteredReminderLogs
//    }
    
    private func checkIfDateIsInWeekInterval(startDate: Date, intervalWeeks: Int) -> Bool {
        
        let startWeek = Calendar.current.component(.weekOfYear, from: startDate)
        let targetWeek = Calendar.current.component(.weekOfYear, from: date)
        
        var currentWeekInYear = startWeek
        
        while currentWeekInYear <= targetWeek {
            if currentWeekInYear == targetWeek {
                return true
            } else {
                currentWeekInYear += intervalWeeks
            }
        }
        
        return false
    }
    
    private func checkIfDateInWeekdays(weekDays: Set<Int>) -> Bool {
        let weekdayOfDate = Calendar.current.component(.weekday, from: date)
        return weekDays.contains(weekdayOfDate)
    }
    
    private func checkIfDateIsSameWeekday(startDate: Date) -> Bool {
        let weekdayOfDate = Calendar.current.component(.weekday, from: date)
        let weekdayOfStartDate = Calendar.current.component(.weekday, from: startDate)
        return weekdayOfDate == weekdayOfStartDate
    }
    
    
    // MARK: - Hashable
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(date)
        hasher.combine(reminders)
        hasher.combine(loggedReminders)
    }
    
    public static func == (lhs: CalendarDay, rhs: CalendarDay) -> Bool {
        return lhs.date == rhs.date && lhs.reminders == rhs.reminders && lhs.loggedReminders == rhs.loggedReminders
    }
}
