//
//  Reminder.swift
//  Model
//
//  Created by Krishna Venkatramani on 17/01/2026.
//

import Foundation
import CoreData

@objc(Reminder)
public final class Reminder: NSObject, CoreDataEntity {
    @NSManaged public private(set) var title: String!
    @NSManaged private var iconName: String!
    @NSManaged public private(set) var date: Date!

    
    // MARK: - Create
    
    static func createReminder(context: NSManagedObjectContext, title: String, iconName: String, date: Date) -> Reminder {
        let reminder = create(context: context)
        reminder.title = title
        reminder.iconName = iconName
        reminder.date = date
        return reminder
    }
}
