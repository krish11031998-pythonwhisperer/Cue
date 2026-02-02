//
//  ReminderTask.swift
//  Cue
//
//  Created by Krishna Venkatramani on 01/02/2026.
//

import CoreData

@objc(ReminderTask)
public final class ReminderTask: NSManagedObject, CoreDataEntity {
    
    @NSManaged public private(set) var title: String
    @NSManaged public private(set) var icon: CueIcon!
    @NSManaged public private(set) var reminder: Reminder!
    
    
    // MARK: - Create
    
    public static func createTask(context: NSManagedObjectContext, title: String, emoji: String, reminder: Reminder) -> ReminderTask {
        let reminderTask = create(context: context)
        reminderTask.title = title
        reminderTask.icon = .init(symbol: nil , emoji: emoji)
        reminderTask.reminder = reminder
        return reminderTask
    }
    
    public static func createTask(context: NSManagedObjectContext, title: String, symbol: String, reminder: Reminder) -> ReminderTask {
        let reminderTask = create(context: context)
        reminderTask.title = title
        reminderTask.icon = .init(symbol: symbol , emoji: nil)
        reminderTask.reminder = reminder
        return reminderTask
    }
    
    
    // MARK: - Delete

    public func delete(context: NSManagedObjectContext) {
        context.delete(self)
        context.saveContext()
    }
}
