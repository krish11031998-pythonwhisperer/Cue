//
//  ReminderModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 02/02/2026.
//

import Foundation
import CoreData

public struct ReminderModel: Hashable, Sendable {
    public let objectId: NSManagedObjectID!
    public let title: String
    public let icon: CueIcon
    public let date: Date
    public let tasks: [CueTask]
    public let schedule: ReminderSchedule?
    
    public init(title: String, icon: CueIcon, date: Date, tasks: [CueTask], schedule: ReminderSchedule?) {
        self.title = title
        self.icon = icon
        self.date = date
        self.tasks = tasks
        self.schedule = schedule
        self.objectId = nil
    }
    
    public init(from reminder: Reminder) {
        self.title = reminder.title
        self.icon = reminder.icon
        self.date = reminder.date
        self.tasks = reminder.tasks
        self.schedule = .init(from: reminder.schedule)
        self.objectId = reminder.objectID
    }
}
