//
//  ReminderTaskLog.swift
//  Cue
//
//  Created by Krishna Venkatramani on 07/02/2026.
//

import CoreData

@objc(ReminderTaskLog)
public final class ReminderTaskLog: CueLog, CoreDataEntity {
    
    @NSManaged public var reminderTask: ReminderTask!
    
    // MARK: - Create
    
    @discardableResult
    internal static func createReminderTaskLog(date: Date, context: NSManagedObjectContext, reminderTask: ReminderTask) -> ReminderTaskLog {
        let reminderTaskLog = create(context: context)
        reminderTaskLog.date = date
        reminderTaskLog.reminderTask = reminderTask
        context.saveContext()
        return reminderTaskLog
    }
    
    
    // MARK: - Delete
    
    public func delete(context: NSManagedObjectContext) {
        context.delete(self)
        context.saveContext()
    }
    
    static func deleteLog(at date: Date, reminderTask: ReminderTask, context: NSManagedObjectContext) {
        Self.fetchLogsWithinTimeRange(context: context, startTime: date.startOfDay, endTime: date.endOfDay).forEach { log in
            guard let reminderLog = log as? ReminderTaskLog else { return }
            if reminderLog.reminderTask == reminderTask {
                reminderLog.delete(context: context)
            }
        }
        context.saveContext()
    }
}
