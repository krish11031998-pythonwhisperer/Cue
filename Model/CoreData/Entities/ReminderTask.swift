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
    @NSManaged public internal(set) var reminder: Reminder!
    @NSManaged public internal(set) var reminderTaskLogs: NSSet!
    
    
    // MARK: - Create
    
    @discardableResult
    public static func createTask(context: NSManagedObjectContext, title: String, icon: CueIcon) -> ReminderTask {
        let reminderTask = create(context: context)
        reminderTask.title = title
        reminderTask.icon = icon
        return reminderTask
    }
    
    
    // MARK: - Update
    
    public func updateProperties(title: String, icon: CueIcon) {
        self.title = title
        self.icon = icon
    }
    
    // MARK: - Delete

    public func delete(context: NSManagedObjectContext) {
        context.delete(self)
        context.saveContext()
    }
}
