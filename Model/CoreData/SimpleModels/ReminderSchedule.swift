//
//  ReminderSchedule.swift
//  Cue
//
//  Created by Krishna Venkatramani on 02/02/2026.
//

import Foundation

public struct ReminderSchedule: Hashable, Sendable {
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
}
