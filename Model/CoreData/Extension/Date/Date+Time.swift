//
//  Date+Time.swift
//  Cue
//
//  Created by Krishna Venkatramani on 28/01/2026.
//

import Foundation

// MARK: - Date -> String

internal extension Date {
    func timeBuilder() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter.string(from: self)
    }
    
    var singleDaySymbol: String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .current
        dateFormatter.dateFormat = "E"
        return dateFormatter.string(from: self)
    }
    
    var shortDaySymbol: String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .current
        dateFormatter.dateFormat = "EE"
        return dateFormatter.string(from: self)
    }
    
    var longDaySymbol: String {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .current
        dateFormatter.dateFormat = "EEEE"
        return dateFormatter.string(from: self)
    }
    
    var day: Int {
        let date = Calendar.current.component(.day, from: self)
        return date
    }
    
    var month: Int {
        let date = Calendar.current.component(.month, from: self)
        return date
    }
    
    var year: Int {
        let date = Calendar.current.component(.year, from: self)
        return date
    }
    
    var weekDay: Int {
        let date = Calendar.current.component(.weekday, from: self)
        return date
    }
    
    var hours: Int {
        let component = Calendar.current.component(.hour, from: self)
        return component
    }
    
    var minutes: Int {
        let component = Calendar.current.component(.minute, from: self)
        return component
    }
    
    var seconds: Int {
        let component = Calendar.current.component(.second, from: self)
        return component
    }
    
    func shortWeekDayString() -> String {
        Calendar.current.shortWeekdaySymbols[weekDay - 1]
    }
    
    func weekDayString() -> String {
        Calendar.current.weekdaySymbols[weekDay - 1]
    }
    
    func shortMonthString() -> String {
        Calendar.current.shortMonthSymbols[month - 1]
    }
    
    func dateStringFormatter() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy"
        return formatter.string(from: self)
    }
}


// MARK: - String - Date

public extension String {
    
    /// Converts time only (HH:mm:ss) to a date
    func timeToDate() -> Date {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        let date = timeFormatter.date(from: self)
        return date ?? .now
    }
}



// MARK: - TimeInterval + String

internal extension String {
    static func formattedTimelineInterval(_ interval: TimeInterval) -> String {
        var result: String = ""
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit
        
        let hours: TimeInterval = TimeInterval(interval / 60).rounded(.down)
        if hours > 0 {
            let hourMeasurement = Measurement(value: hours, unit: UnitDuration.hours)
            result += formatter.string(from: hourMeasurement) + " "
        }
        
        let minutes = interval.truncatingRemainder(dividingBy: 60)
        if minutes > 0 {
            let measurement = Measurement(value: minutes, unit: UnitDuration.minutes)
            result += formatter.string(from: measurement)            
        }
        
        return result
    }
    
    static func formatttedTimeIntervalToDate(_ interval: TimeInterval) -> String {
        let date = Date.now.startOfDay.addingTimeInterval(interval)
        return date.timeBuilder()
        
    }
}
