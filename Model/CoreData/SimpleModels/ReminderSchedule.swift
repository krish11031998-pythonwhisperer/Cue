//
//  ReminderSchedule.swift
//  Cue
//
//  Created by Krishna Venkatramani on 02/02/2026.
//

import Foundation

public struct ReminderSchedule: Hashable, Comparable, Sendable {
    public let hour: Int
    public let minute: Int
    public let intervalWeeks: Int?
    public let weekdays: Set<Int>?
    public let calendarDates: Set<Int>?
    
    public init(hour: Int, minute: Int, intervalWeeks: Int?, weekdays: Set<Int>?, calendarDates: Set<Int>?) {
        self.hour = hour
        self.minute = minute
        self.intervalWeeks = intervalWeeks
        self.weekdays = weekdays
        self.calendarDates = calendarDates
    }
    
    public init(from schedule: CueReminderSchedule) {
        self.hour = schedule.hour
        self.minute = schedule.minute
        self.intervalWeeks = schedule.intervalWeeks
        self.weekdays = schedule.weekdays
        self.calendarDates = schedule.calendarDates
    }
    
    public var timeScheduled: Date {
        var dateComponents = Calendar.current.dateComponents([.minute, .hour, .calendar], from: .now)
        dateComponents.hour = hour
        dateComponents.minute = minute
        return dateComponents.date ?? .now
    }
    
    public var scheduleForToday: Date {
        var dateComponents = Calendar.current.dateComponents([.minute, .hour, .day, .month, .year, .calendar], from: .now)
        dateComponents.hour = hour
        dateComponents.minute = minute
        return dateComponents.date ?? .now
    }
    
    public static func < (lhs: ReminderSchedule, rhs: ReminderSchedule) -> Bool {
        return lhs.timeScheduled < rhs.timeScheduled
    }
}


// MARK: - Occurrence

public extension ReminderSchedule {

    /// Whether this schedule produces an occurrence on `date`, for a reminder that starts on `startDate`.
    ///
    /// Mirrors the filtering `CalendarDay` applies when building a day's reminders.
    func contains(_ date: Date, startingFrom startDate: Date) -> Bool {
        guard date.startOfDay >= startDate.startOfDay else { return false }

        // Repeats every `intervalWeeks` weeks, on the given weekdays.
        if let intervalWeeks, intervalWeeks > 0 {
            guard let weekdays, isInWeekInterval(date, startDate: startDate, intervalWeeks: intervalWeeks)
            else { return false }
            return weekdays.contains(Calendar.current.component(.weekday, from: date))
        }

        // Repeats on given days of the month.
        if let calendarDates, !calendarDates.isEmpty {
            return calendarDates.contains(Calendar.current.component(.day, from: date))
        }

        // One-off.
        return date.startOfDay == startDate.startOfDay
    }

    /// Whether this schedule produces an occurrence today, for a reminder that starts on `startDate`.
    func containsToday(startingFrom startDate: Date) -> Bool {
        contains(.now, startingFrom: startDate)
    }

    private func isInWeekInterval(_ date: Date, startDate: Date, intervalWeeks: Int) -> Bool {
        let startWeek = Calendar.current.component(.weekOfYear, from: startDate)
        let targetWeek = Calendar.current.component(.weekOfYear, from: date)
        guard targetWeek >= startWeek else { return false }
        return (targetWeek - startWeek) % intervalWeeks == 0
    }
}
