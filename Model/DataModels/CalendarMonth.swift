//
//  CalendarMonth.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/09/2026.
//

import Foundation

public struct CalendarMonth: Hashable, Sendable, Identifiable {
    
    public class Day: CalendarDay, @unchecked Sendable {
        
        override public func hash(into hasher: inout Hasher) {
            hasher.combine(date)
            hasher.combine(reminders)
            hasher.combine(loggedReminders)
            hasher.combine(loggedReminderTasks)
        }
        
        public static func == (lhs: Day, rhs: Day) -> Bool {
            return lhs.date == rhs.date && lhs.reminders == rhs.reminders && lhs.loggedReminders == rhs.loggedReminders && lhs.loggedReminderTasks == rhs.loggedReminderTasks
        }
    }
    
    public nonisolated let month: Int
    public var days: [Day]
    
    public var firstDayInMonth: Int {
        guard let firstDay = days.first else {
            fatalError("Must have a first Day!")
        }
        
        return firstDay.date.weekDayValue
    }
    
    public init(month: Int, days: [CalendarMonth.Day]) {
        self.month = month
        self.days = days
    }
    
    @concurrent
    public static func fetch(month: Int) async -> CalendarMonth {
        let calendarDays = await CalendarManager.shared.setupCalendayDaysInCurrentYear(month: month)
        return .init(month: month, days: calendarDays.map { Day(date: $0.date, reminders: $0.reminders, loggedReminders: $0.loggedReminders, loggedReminderTasks: $0.loggedReminderTasks) })
    }
    
    
    // MARK: - Equatable
    
    public static func == (lhs: CalendarMonth, rhs: CalendarMonth) -> Bool {
        if lhs.month != rhs.month {
            return false
        }
        
        return lhs.days == rhs.days
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(month)
        hasher.combine(days)
    }
    
    public var id: String {
        return "\(Calendar.current.monthSymbols[month - 1])"
    }
}
