//
//  CalendarMonth.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/09/2026.
//

import Foundation

public struct CalendarMonth: Hashable, Sendable, Identifiable {
    
    public nonisolated let month: Int
    public var days: [CalendarDay]
    
    public var firstDayInMonth: Int {
        guard let firstDay = days.first else {
            fatalError("Must have a first Day!")
        }
        
        return firstDay.date.weekDayValue
    }
    
    public init(month: Int, days: [CalendarDay]) {
        self.month = month
        self.days = days
    }
    
    @concurrent
    public static func fetch(month: Int) async -> CalendarMonth {
        let calendarDays = await CalendarManager.shared.setupCalendayDaysInCurrentYear(month: month)
        return .init(month: month, days: calendarDays)
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
