//
//  CueReminderSchedule.swift
//  Model
//
//  Created by Krishna Venkatramani on 27/01/2026.
//

import Foundation
import CoreData

@objc(CueReminderSchedule)
public class CueReminderSchedule: NSObject, NSSecureCoding, Codable {
    
    public static var supportsSecureCoding: Bool { true }
    
    public let hour: Int
    public let minute: Int
    public let intervalWeeks: Int?
    public let weekdays: Set<Int>?
    public let calendarDates: Set<Int>?
    
    enum Keys: String, CodingKey {
        case hour
        case minute
        case startDate
        case intervalWeeks
        case weekdays
        case calendarDates
    }
    
    public init(hour: Int, minute: Int, intervalWeeks: Int?, weekdays: Set<Int>?, calendarDates: Set<Int>?) {
        self.hour = hour
        self.minute = minute
        self.intervalWeeks = intervalWeeks
        self.weekdays = weekdays
        self.calendarDates = calendarDates
    }
    
    public required init?(coder: NSCoder) {
        let hour = coder.decodeInteger(forKey: Keys.hour.rawValue)
        let minute = coder.decodeInteger(forKey: Keys.minute.rawValue)
        let intervalWeeks = coder.decodeObject(of: NSNumber.self, forKey: Keys.intervalWeeks.rawValue) as? Int
        let weekdays = coder.decodeObject(of: NSSet.self, forKey: Keys.weekdays.rawValue) as? Set<Int>
        let calendarDates = coder.decodeObject(of: NSSet.self, forKey: Keys.calendarDates.rawValue) as? Set<Int>
        
        self.hour = hour
        self.minute = minute
        self.intervalWeeks = intervalWeeks
        self.weekdays = weekdays
        self.calendarDates = calendarDates
    }
    
    public func encode(with coder: NSCoder) {
        
        coder.encode(hour, forKey: Keys.hour.rawValue)
        coder.encode(minute, forKey: Keys.minute.rawValue)
        
        if let intervalWeeks = intervalWeeks {
            coder.encode(intervalWeeks as NSNumber, forKey: Keys.intervalWeeks.rawValue)
        }
        
        if let weekdays = weekdays {
            coder.encode(weekdays as NSSet, forKey: Keys.weekdays.rawValue)
        }
        
        if let calendarDates = calendarDates {
            coder.encode(calendarDates as NSSet, forKey: Keys.calendarDates.rawValue)
        }
    }
    
}
