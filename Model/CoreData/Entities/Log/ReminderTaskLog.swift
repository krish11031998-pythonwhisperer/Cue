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
    
    public func delete(context: NSManagedObjectContext) {
        context.delete(self)
        context.saveContext()
    }
}
