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
    public let notificationID: UUID
    public let notificationType: ReminderNotification
    public let title: String
    public let icon: CueIcon
    public let date: Date
    public let snoozeDuration: TimeInterval
    public let tasks: [ReminderTaskModel]
    public let schedule: ReminderSchedule?
    
    public init(notificationID: UUID = .init(), notificationType: ReminderNotification, title: String, icon: CueIcon, date: Date, snoozeDuration: TimeInterval, tasks: [ReminderTaskModel], schedule: ReminderSchedule?) {
        self.title = title
        self.icon = icon
        self.date = date
        self.tasks = tasks
        self.schedule = schedule
        self.objectId = nil
        self.notificationID = notificationID
        self.snoozeDuration = snoozeDuration
        self.notificationType = notificationType
    }
    
    public init(from reminder: Reminder) {
        self.title = reminder.title
        self.icon = reminder.icon
        self.date = reminder.date
        self.tasks = reminder.tasks.map {ReminderTaskModel(from: $0) }
        self.schedule = .init(from: reminder.schedule)
        self.objectId = reminder.objectID
        self.notificationID = reminder.notificationID
        self.notificationType = reminder.reminderNotification
        self.snoozeDuration = reminder.snoozeDuration
    }
}
