//
//  ReminderLog.swift
//  Cue
//
//  Created by Krishna Venkatramani on 01/02/2026.
//

import CoreData

@objc(ReminderLog)
public final class ReminderLog: NSManagedObject, CoreDataEntity {
    
    @NSManaged public private(set) var date: Date!
    @NSManaged public private(set) var reminder: Reminder!
    @NSManaged public private(set) var completedReminderTasks: NSSet!
    @NSManaged public private(set) var isCompleted: Bool
 
    
    // MARK: - Create
    
    @discardableResult
    internal static func createReminderLog(date: Date, context: NSManagedObjectContext, reminder: Reminder) -> ReminderLog {
        let reminderLog = create(context: context)
        reminderLog.date = date
        reminderLog.reminder = reminder
        context.saveContext()
        return reminderLog
    }
    
    
    // MARK: - Delete
    
    public func delete(context: NSManagedObjectContext) {
        context.delete(self)
        context.saveContext()
    }
    
    static func deleteLog(at date: Date, reminder: Reminder, context: NSManagedObjectContext) {
        Self.fetchReminderLogsWithinTimeRange(context: context, startTime: date.startOfDay, endTime: date.endOfDay).forEach { log in
            if log.reminder == reminder {
                log.delete(context: context)                
            }
        }
        context.saveContext()
    }
    
    
    // MARK: - Fetch
    
    public static func fetchReminderLogsWithinTimeRange(context: NSManagedObjectContext, startTime: Date, endTime: Date) -> [ReminderLog] {
        let dateOfLogPredicate = NSPredicate(format: "date >= %@ AND date < %@", startTime as NSDate, endTime as NSDate)
        return Self.fetch(context: context, predicate: dateOfLogPredicate, sortDescriptors: []) ?? []
    }
}
