//
//  Reminder.swift
//  Model
//
//  Created by Krishna Venkatramani on 17/01/2026.
//

import Foundation
import CoreData

@objc(Reminder)
public final class Reminder: NSManagedObject, CoreDataEntity, Identifiable {
    @NSManaged public private(set) var title: String!
    @NSManaged public private(set) var icon: CueIcon!
    @NSManaged public private(set) var date: Date!
    @NSManaged private var tasksContainer: CueTaskContainer!
    @NSManaged public private(set) var schedule: CueReminderSchedule!

    public var tasks: [CueTask] {
        tasksContainer?.tasks ?? []
    }
    
    public struct ScheduleBuilder {
        public var hour: Int
        public var minute: Int
        public var intervalWeek: Int?
        public var weekdays: Set<Int>?
        public var dates: Set<Int>?
        
        public init(_ date: Date) {
            self.hour = date.hours
            self.minute = date.minutes
            self.intervalWeek = nil
            self.weekdays = nil
            self.dates = nil
        }
        
        public init(hour: Int = 0, minute: Int = 0, intervalWeek: Int?, weekdays: Set<Int>?, dates: Set<Int>?) {
            self.hour = hour
            self.minute = minute
            self.intervalWeek = intervalWeek
            self.weekdays = weekdays
            self.dates = dates
        }
    }
    
    // MARK: - Create
    
    static func createReminder(context: NSManagedObjectContext, title: String, symbol: String, date: Date, schedule: ScheduleBuilder?,  tasks: [CueTask]) -> Reminder {
        let reminder = create(context: context)
        reminder.title = title
        reminder.icon = .init(symbol: symbol, emoji: nil)
        reminder.date = date
        reminder.tasksContainer = .init(tasks: tasks)
        reminder.schedule = .init(hour: schedule?.hour ?? 0, minute: schedule?.minute ?? 0, intervalWeeks: schedule?.intervalWeek, weekdays: schedule?.weekdays, calendarDates: schedule?.dates)
        return reminder
    }
    
    static func createReminder(context: NSManagedObjectContext, title: String, emoji: String, date: Date, schedule: ScheduleBuilder? = nil, tasks: [CueTask]) -> Reminder {
        let reminder = create(context: context)
        reminder.title = title
        reminder.icon = .init(symbol: nil, emoji: emoji)
        reminder.date = date
        reminder.tasksContainer = .init(tasks: tasks)
        reminder.schedule = .init(hour: schedule?.hour ?? 0, minute: schedule?.minute ?? 0, intervalWeeks: schedule?.intervalWeek, weekdays: schedule?.weekdays, calendarDates: schedule?.dates)
        return reminder
    }
    
    
    // MARK: - Delete
    
    func delete(context: NSManagedObjectContext) {
        context.delete(self)
        context.saveContext()
    }
    
    
    // MARK: - Identifiable
    
    public var id: Int {
        var hasher = Hasher()
        hasher.combine(title)
        hasher.combine(icon)
        hasher.combine(date)
        hasher.combine(tasks)
        hasher.combine(schedule)
        return hasher.finalize()
    }
}
