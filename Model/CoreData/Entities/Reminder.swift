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
    @NSManaged public private(set) var notificationID: UUID!
    @NSManaged public private(set) var title: String!
    @NSManaged public private(set) var icon: CueIcon!
    @NSManaged public private(set) var date: Date!
    @NSManaged public private(set) var schedule: CueReminderSchedule!
    @NSManaged public private(set) var reminderLogs: NSSet!
    @NSManaged public private(set) var reminderTasks: NSOrderedSet!
    @NSManaged public private(set) var notificationType: NSNumber!
    @NSManaged public private(set) var snoozeDurationRawValue: NSNumber!
    @NSManaged public private(set) var tags: NSSet!
    
    public var tasks: [ReminderTask] {
        reminderTasks.array as! [ReminderTask]
    }
    
    internal var mutatableTasks: NSMutableOrderedSet {
        mutableOrderedSetValue(forKey: "reminderTasks")
    }
    
    internal var mutatableTags: NSMutableOrderedSet {
        mutableOrderedSetValue(forKey: "tags")
    }
    
    public var tagsArray: [CueTag] {
        tags.allObjects as! [CueTag]
    }
    
    internal var mutableTagSet: NSMutableOrderedSet {
        mutableOrderedSetValue(forKey: "tags")
    }
    
    public var reminderNotification: ReminderNotification {
        get {
            if let notificationType = notificationType as? Int {
                .init(rawValue: notificationType)!
            } else {
                fatalError("Invalid ReminderNotification")
            }
        }
        
        set {
            notificationType = newValue.rawValue as NSNumber
        }
    }
    
    public var snoozeDuration: TimeInterval {
        get {
            snoozeDurationRawValue!.doubleValue
        }
        
        set {
            snoozeDurationRawValue = newValue as NSNumber
        }
    }
    
    public var logs: [ReminderLog] {
        reminderLogs.allObjects as! [ReminderLog]
    }
    
    public struct ScheduleBuilder: Hashable, Sendable {
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
    
    static func createReminder(context: NSManagedObjectContext, title: String, icon: CueIcon, date: Date, snoozeDuration: TimeInterval, schedule: ScheduleBuilder? = nil, reminderNotification: ReminderNotification) -> Reminder {
        let reminder = create(context: context)
        reminder.notificationID = UUID()
        reminder.title = title
        reminder.icon = icon
        reminder.date = date
        reminder.snoozeDuration = snoozeDuration
        reminder.reminderNotification = reminderNotification
        reminder.schedule = .init(hour: schedule?.hour ?? 0, minute: schedule?.minute ?? 0, intervalWeeks: schedule?.intervalWeek, weekdays: schedule?.weekdays, calendarDates: schedule?.dates)
        return reminder
    }
    
    public func updateProperties(title: String, icon: CueIcon, date: Date, snoozeDuration: TimeInterval, scheduleBuilder: ScheduleBuilder? = nil, reminderNotification: ReminderNotification) {
        self.title = title
        self.icon = icon
        self.date = date
        self.snoozeDuration = snoozeDuration
        self.reminderNotification = reminderNotification
        self.schedule = .init(hour: scheduleBuilder?.hour ?? 0,
                              minute: scheduleBuilder?.minute ?? 0,
                              intervalWeeks: scheduleBuilder?.intervalWeek,
                              weekdays: scheduleBuilder?.weekdays,
                              calendarDates: scheduleBuilder?.dates)
    }
    
    
    // MARK: - Update
    
    func removeTasks() {
        self.mutatableTasks.removeAllObjects()
    }
    
    func removeTags() {
        self.mutatableTags.removeAllObjects()
    }
    
    
    // MARK: - Delete
    
    public func delete(context: NSManagedObjectContext) {
        context.delete(self)
        context.saveContext()
    }
    
    
    // MARK: - Fetch
    
    internal static func fetchRemindersWithNotification(context: NSManagedObjectContext) -> [Reminder] {
        let predicate = NSPredicate(format: "notificationType == %d", ReminderNotification.notification.rawValue)
        return Self.fetch(context: context, predicate: predicate) ?? []
    }
    
    internal static func fetchRemindersWithAlarm(context: NSManagedObjectContext) -> [Reminder] {
        let predicate = NSPredicate(format: "notificationType == %d", ReminderNotification.alarm.rawValue)
        return Self.fetch(context: context, predicate: predicate) ?? []
    }
    
    internal static func fetchRemindersWithTags(context: NSManagedObjectContext, names: [String]) -> [Reminder] {
        let predicate = {
            var orPredicates: [NSPredicate] = []
            for name in names {
                let predicate = NSPredicate(format: "ANY tags.name == %@", name)
                orPredicates.append(predicate)
            }
            return NSCompoundPredicate(orPredicateWithSubpredicates: orPredicates)
        }()
        
        return Self.fetch(context: context, predicate: predicate, sortDescriptors: []) ?? []
    }
    
    // MARK: - Add Tag
    
    func updateTags(_ tags:[CueTag]) {
        mutableTagSet.removeAllObjects()
        mutableTagSet.addObjects(from: tags)
    }
    
    
    // MARK: - Identifiable
    
    public var id: Int {
        var hasher = Hasher()
        hasher.combine(title)
        hasher.combine(icon)
        hasher.combine(date)
        hasher.combine(tasks)
        hasher.combine(schedule)
        hasher.combine(logs)
        return hasher.finalize()
    }
}
