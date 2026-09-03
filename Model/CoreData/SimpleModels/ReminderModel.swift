//
//  ReminderModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 02/02/2026.
//

import Foundation
import CoreData
@preconcurrency import FamilyControls

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
    public let colorName: String
    public let focusSession: FocusSession?
    
    public init(notificationID: UUID = .init(), notificationType: ReminderNotification, title: String, icon: CueIcon, date: Date, snoozeDuration: TimeInterval, tasks: [ReminderTaskModel], tags: [TagModel], schedule: ReminderSchedule?, colorName: String, focusSession: FocusSession?) {
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
        self.colorName = colorName
        self.focusSession = focusSession
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
        self.colorName = reminder.colorName
        if let focusSession = reminder.focusSession {
            self.focusSession = FocusSession(from: focusSession)
        } else {
            self.focusSession = nil
        }
    }
    
    public static func exampleOne() -> ReminderModel {
        .init(notificationType: .notification, title: "Example", icon: .init(symbol: nil, emoji: "🧘"), date: .now, snoozeDuration: 0, tasks: [], tags: [], schedule: nil, colorName: "sky", focusSession: nil)
    }
    
    public static func exampleTwo() -> ReminderModel {
        .init(notificationType: .alarm, title: "Flight to Paris", icon: .init(symbol: "✈️", emoji: "🇫🇷"), date: Calendar.current.date(byAdding: .month, value: 2, to: Date()) ?? Date(), snoozeDuration: 3600, tasks: [], tags: [], schedule: nil, colorName: "sky", focusSession: nil)
    }

    public static func exampleThree() -> ReminderModel {
        let tasks: [ReminderTaskModel] = [
            .init(title: "Milk", icon: .init(symbol: nil, emoji: "🥛")),
            .init(title: "Bread", icon: .init(symbol: nil, emoji: "🥖"))
        ]
        
        return .init(notificationType: .notification, title: "Grocery List", icon: .init(symbol: nil, emoji:  "🛒"), date: .now, snoozeDuration: 0, tasks: tasks, tags: [], schedule: nil, colorName: "sky", focusSession: nil)
    }

    public static func exampleFour() -> ReminderModel {
        let schedule = ReminderSchedule(hour: 10, minute: 0, intervalWeeks: 1, weekdays: nil, calendarDates: nil)
        return .init(notificationType: .notification, title: "Daily Check-in", icon: .init(symbol: nil, emoji: "✅"), date: .now, snoozeDuration: 0, tasks: [], tags: [], schedule: schedule, colorName: "sky", focusSession: nil)
    }
}

extension ReminderModel {
    
    public struct FocusSession: Hashable, Sendable, Identifiable {
        public var objectId: NSManagedObjectID!
        public let name: String
        public let sessionType: FocusSessionKind
        public let timerDuration: TimeInterval
        public let breakDuration: TimeInterval
        public let blockedApps: FamilyActivitySelection?
        public let alarm: FocusSessionAlarmOption
        public let sessionCount: Int?
        public let imageFileName: String?

        public init(name: String, sessionType: FocusSessionKind, timerDuration: TimeInterval, breakDuration: TimeInterval, blockedApps: FamilyActivitySelection?, alarm: FocusSessionAlarmOption, sessionCount: Int?, imageFileName: String? = nil) {
            self.name = name
            self.sessionType = sessionType
            self.timerDuration = timerDuration
            self.breakDuration = breakDuration
            self.blockedApps = blockedApps
            self.alarm = alarm
            self.sessionCount = sessionCount
            self.imageFileName = imageFileName
            self.objectId = nil
        }

        public init(from session: Model.FocusSession) {
            self.name = session.name
            self.sessionType = session.focusSessionType
            self.timerDuration = session.timerDuration
            self.breakDuration = session.breakDuration
            self.blockedApps = session.blockedApps
            self.alarm = session.alarm
            self.sessionCount = session.sessionCount
            self.imageFileName = session.imageFileName
            self.objectId = session.objectID
        }
        
        public static func ==(lhs: FocusSession, rhs: FocusSession) -> Bool {
            lhs.name == rhs.name &&
            lhs.sessionType == rhs.sessionType &&
            lhs.timerDuration == rhs.timerDuration &&
            lhs.breakDuration == rhs.breakDuration &&
            lhs.blockedApps == rhs.blockedApps &&
            lhs.alarm == rhs.alarm &&
            lhs.sessionCount == rhs.sessionCount &&
            lhs.imageFileName == rhs.imageFileName
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(name)
            hasher.combine(sessionType)
            hasher.combine(timerDuration)
            hasher.combine(breakDuration)
            hasher.combine(alarm)
            hasher.combine(sessionCount)
            hasher.combine(imageFileName)
        }
        
        public var id: Int {
            hashValue
        }
    }
    
}
