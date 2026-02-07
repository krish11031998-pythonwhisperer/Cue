//
//  ReminderLog.swift
//  Cue
//
//  Created by Krishna Venkatramani on 01/02/2026.
//

import CoreData

@objc(ReminderLog)
public final class ReminderLog: CueLog, CoreDataEntity {
    
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
        Self.fetchLogsWithinTimeRange(context: context, startTime: date.startOfDay, endTime: date.endOfDay).forEach { log in
            guard let reminderLog = log as? ReminderLog else { return }
            if reminderLog.reminder == reminder {
                reminderLog.delete(context: context)                
            }
        }
        context.saveContext()
    }
}
