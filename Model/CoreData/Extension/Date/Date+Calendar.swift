//
//  Date+Calendar.swift
//  Cue
//
//  Created by Krishna Venkatramani on 28/01/2026.
//

import Foundation

internal extension Date {
    func currentMonth() -> [Date] {
        let calendar = Calendar.current
        var currentMonthComponents = calendar.dateComponents([.month, .year], from: .now)
        currentMonthComponents.day = 1
        var dates: [Date] = []
        guard let firstDateOfCurrentMonth = calendar.date(from: currentMonthComponents),
              let range = calendar.range(of: .day, in: .month, for: firstDateOfCurrentMonth)
        else { return dates }
        
        dates.append(firstDateOfCurrentMonth)
        
        var endDateOfCurrentMonthComponents = currentMonthComponents
        endDateOfCurrentMonthComponents.day = range.count
        let firstDay = currentMonthComponents.day ?? 1
        for dateIdx in (firstDay + 1)...range.count {
            var dateComponent = currentMonthComponents
            dateComponent.day = dateIdx
            
            if let date = calendar.date(from: dateComponent) {
                dates.append(date)
            }
        }
        
        return dates
    }
    
    var startOfDay: Date {
        var dateComponents = Calendar.current.dateComponents([.day, .month, .year], from: self)
        dateComponents.calendar = .current
        dateComponents.hour = 0
        dateComponents.minute = 0
        return dateComponents.date!
    }
    
    var endOfDay: Date {
        var dateComponents = Calendar.current.dateComponents([.day, .month, .year], from: self)
        dateComponents.calendar = .current
        dateComponents.hour = 24
        dateComponents.minute = 0
        return dateComponents.date!
    }
    
    var nextDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: self)!
    }
    
    var previousDay: Date {
        Calendar.current.date(byAdding: .day, value: -1, to: self)!
    }
    
    var weekDayValue: Int {
        let component = Calendar.current.component(.weekday, from: self)
        return component
    }
    
    var startOfWeek: Date {
            let gregorian = Calendar(identifier: .gregorian)
            guard let sunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return self }
            return gregorian.date(byAdding: .day, value: 0, to: sunday)!
        }
        
    var endOfWeek: Date {
        let gregorian = Calendar(identifier: .gregorian)
        guard let sunday = gregorian.date(from: gregorian.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)) else { return self }
        return gregorian.date(byAdding: .day, value: 7, to: sunday)!
    }
    
    var startOfMonth: Date {
        let calendar = Calendar.current
        var currentDateComponents = calendar.dateComponents([.year, .month, .day], from: self)
        currentDateComponents.day = 1
        currentDateComponents.calendar = calendar
        guard let startOfMonth = currentDateComponents.date else { return self }
        return startOfMonth
    }
    
    var endOfMonth: Date {
        let calendar = Calendar.current
        let startOfMonth = startOfMonth
        guard let endOfMonth = calendar.date(byAdding: .init(month: 1, day: -1), to: startOfMonth) else { return self }
        return endOfMonth
    }
    
    var startOfYear: Date {
        let calendar = Calendar.current
        var currentDateComponents = calendar.dateComponents([.year, .month, .day], from: self)
        currentDateComponents.day = 1
        currentDateComponents.month = 1
        currentDateComponents.hour = 0
        currentDateComponents.minute = 0
        currentDateComponents.calendar = calendar
        guard let startOfMonth = currentDateComponents.date else { return self }
        return startOfMonth
    }
    
    var endOfYear: Date {
        let calendar = Calendar.current
        var currentDateComponents = calendar.dateComponents([.year, .month, .day], from: self)
        currentDateComponents.day = 1
        currentDateComponents.month = 1
        currentDateComponents.year = (currentDateComponents.year ?? -1) + 1
        currentDateComponents.hour = 0
        currentDateComponents.minute = 0
        currentDateComponents.calendar = calendar
        guard let startOfMonth = currentDateComponents.date else { return self }
        return startOfMonth
    }
    
    var isToday: Bool {
        self.startOfDay == Date.now.startOfDay
    }
    
    var yesterday: Date {
        var components = Calendar.current.dateComponents([.day, .month, .year], from: self)
        components.calendar = .current
        components.day = components.day! - 1
        return components.date!
    }
    
    var tomorrow: Date {
        var components = Calendar.current.dateComponents([.day, .month, .year], from: self)
        components.calendar = .current
        components.day = components.day! + 1
        return components.date!
    }
    
    func daysLeadingTo(_ count: Int) -> Date {
        var components = Calendar.current.dateComponents([.day, .month, .year], from: self)
        components.calendar = .current
        components.day = components.day! - count
        return components.date!
    }
    
    func daysStartingTo(_ count: Int) -> Date {
        var components = Calendar.current.dateComponents([.day, .month, .year], from: self)
        components.calendar = .current
        components.day = components.day! + count
        return components.date!
    }
    
    
    /// Uses the hour, minutes and seconds of the Date and apply it today's Date to get the time today.
    func timeToday() -> Date? {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: self)
        var todayComponents = Calendar.current.dateComponents(in: .current, from: Self.now.startOfDay)
        todayComponents.hour = components.hour
        todayComponents.minute = components.minute
        todayComponents.second = components.second
        return Calendar.current.date(from: todayComponents)
    }
}
