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
    public let tags: [TagModel]
    public let schedule: ReminderSchedule?
    
    public init(notificationID: UUID = .init(), notificationType: ReminderNotification, title: String, icon: CueIcon, date: Date, snoozeDuration: TimeInterval, tasks: [ReminderTaskModel], tags: [TagModel], schedule: ReminderSchedule?) {
        self.title = title
        self.icon = icon
        self.date = date
        self.tasks = tasks
        self.schedule = schedule
        self.objectId = nil
        self.notificationID = notificationID
        self.snoozeDuration = snoozeDuration
        self.notificationType = notificationType
        self.tags = tags
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
        self.tags = reminder.tagsArray.map { .from($0) }
    }
    
    public static func exampleOne() -> ReminderModel {
        .init(notificationType: .notification, title: "Example", icon: .init(symbol: nil, emoji: "🧘"), date: .now, snoozeDuration: 0, tasks: [], tags: [], schedule: nil)
    }
    
    public static func exampleTwo() -> ReminderModel {
        .init(notificationType: .alarm, title: "Flight to Paris", icon: .init(symbol: "✈️", emoji: "🇫🇷"), date: Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date(), snoozeDuration: 3600, tasks: [], tags: [], schedule: nil)
    }

    public static func exampleThree() -> ReminderModel {
        let tasks: [ReminderTaskModel] = [
            .init(objectId: .init(), title: "Milk", icon: .init(symbol: nil, emoji: "🥛")),
            .init(objectId: .init(), title: "Bread", icon: .init(symbol: nil, emoji: "🥖"))
        ]
        
        return .init(notificationType: .notification, title: "Grocery List", icon: .init(symbol: nil, emoji:  "🛒"), date: .now, snoozeDuration: 0, tasks: tasks, tags: [], schedule: nil)
    }

    public static func exampleFour() -> ReminderModel {
        let schedule = ReminderSchedule(hour: 10, minute: 0, intervalWeeks: 1, weekdays: nil, calendarDates: nil)
        return .init(notificationType: .notification, title: "Daily Check-in", icon: .init(symbol: nil, emoji: "✅"), date: .now, snoozeDuration: 0, tasks: [], tags: [], schedule: schedule)
    }
}
