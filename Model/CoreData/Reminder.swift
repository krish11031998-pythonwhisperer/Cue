//
//  Reminder.swift
//  Model
//
//  Created by Krishna Venkatramani on 17/01/2026.
//

import Foundation
import CoreData

@objc(Reminder)
public final class Reminder: NSManagedObject, CoreDataEntity {
    @NSManaged public private(set) var title: String!
    @NSManaged public private(set) var iconName: String!
    @NSManaged public private(set) var date: Date!
    @NSManaged public private(set) var tasksContainer: CueTaskContainer!

    private var tasks: [CueTask] {
        tasksContainer.tasks
    }
    
    
    // MARK: - Create
    
    static func createReminder(context: NSManagedObjectContext, title: String, iconName: String, date: Date, tasks: [CueTask]) -> Reminder {
        let reminder = create(context: context)
        reminder.title = title
        reminder.iconName = iconName
        reminder.date = date
        reminder.tasksContainer = .init(tasks: tasks)
        return reminder
    }
}
