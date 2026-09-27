//
//  ReminderModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 02/02/2026.
//

import Foundation
import CoreData
import SwiftUI
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
        let schedule = ReminderSchedule(hour: 10, minute: 0, intervalWeeks: 1, weekdays: [1, 2, 4, 6], calendarDates: nil)
        return .init(notificationType: .notification, title: "Daily Check-in", icon: .init(symbol: nil, emoji: "✅"), date: .now, snoozeDuration: 0, tasks: [], tags: [], schedule: schedule, colorName: "sky", focusSession: nil)
    }

    public static func exampleFive() -> ReminderModel {
        let tasks: [ReminderTaskModel] = [
            .init(title: "Pack gym bag", icon: .init(symbol: nil, emoji: "🎒")),
            .init(title: "Fill water bottle", icon: .init(symbol: nil, emoji: "💧")),
            .init(title: "Warm up", icon: .init(symbol: nil, emoji: "🤸")),
            .init(title: "Strength training", icon: .init(symbol: nil, emoji: "🏋️")),
            .init(title: "Stretch & cool down", icon: .init(symbol: nil, emoji: "🧘"))
        ]
        let tags: [TagModel] = [
            .init(id: NSManagedObjectID(), name: "Fitness", color: Color.green, reminderIDs: []),
            .init(id: NSManagedObjectID(), name: "Health", color: Color.red, reminderIDs: []),
            .init(id: NSManagedObjectID(), name: "Morning", color: Color.orange, reminderIDs: [])
        ]
        let schedule = ReminderSchedule(hour: 7, minute: 0, intervalWeeks: 1, weekdays: [2, 4, 6], calendarDates: nil)

        return .init(notificationType: .notification, title: "Go to Gym", icon: .init(symbol: nil, emoji: "💪"), date: .now, snoozeDuration: 0, tasks: tasks, tags: tags, schedule: schedule, colorName: "sky", focusSession: nil)
    }

    public static func exampleSix() -> ReminderModel {
        let tasks: [ReminderTaskModel] = [
            .init(title: "Review lecture notes", icon: .init(symbol: nil, emoji: "📝")),
            .init(title: "Practice problems", icon: .init(symbol: nil, emoji: "🧮")),
            .init(title: "Summarise chapter", icon: .init(symbol: nil, emoji: "📖"))
        ]
        let tags: [TagModel] = [
            .init(id: NSManagedObjectID(), name: "Study", color: Color.blue, reminderIDs: []),
            .init(id: NSManagedObjectID(), name: "Focus", color: Color.purple, reminderIDs: []),
            .init(id: NSManagedObjectID(), name: "Productivity", color: Color.teal, reminderIDs: [])
        ]
        let schedule = ReminderSchedule(hour: 18, minute: 0, intervalWeeks: 1, weekdays: [2, 3, 4, 5], calendarDates: nil)
        let focusSession = FocusSession(name: "Study Pomodoro", sessionType: .pomodoro, timerDuration: 25 * 60, breakDuration: 5 * 60, blockedApps: nil, alarm: .betweenSessions, sessionCount: 4)

        return .init(notificationType: .notification, title: "Study Session", icon: .init(symbol: nil, emoji: "📚"), date: .now, snoozeDuration: 0, tasks: tasks, tags: tags, schedule: schedule, colorName: "peach", focusSession: focusSession)
    }

    public static func exampleSeven() -> ReminderModel {
        let tasks: [ReminderTaskModel] = [
            .init(title: "Find a quiet spot", icon: .init(symbol: nil, emoji: "🛋️")),
            .init(title: "Make a cup of tea", icon: .init(symbol: nil, emoji: "🍵")),
            .init(title: "Read two chapters", icon: .init(symbol: nil, emoji: "📖"))
        ]
        let tags: [TagModel] = [
            .init(id: NSManagedObjectID(), name: "Reading", color: Color.indigo, reminderIDs: []),
            .init(id: NSManagedObjectID(), name: "Wind Down", color: Color.mint, reminderIDs: []),
            .init(id: NSManagedObjectID(), name: "Self Care", color: Color.pink, reminderIDs: [])
        ]
        let schedule = ReminderSchedule(hour: 21, minute: 30, intervalWeeks: 1, weekdays: [1, 7], calendarDates: nil)
        let focusSession = FocusSession(name: "Reading Time", sessionType: .classic, timerDuration: 45 * 60, breakDuration: 0, blockedApps: nil, alarm: .endOfSession, sessionCount: nil)

        return .init(notificationType: .notification, title: "Read a Book", icon: .init(symbol: nil, emoji: "📕"), date: .now, snoozeDuration: 0, tasks: tasks, tags: tags, schedule: schedule, colorName: "lavender", focusSession: focusSession)
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


// MARK: - Occurrence

public extension ReminderModel {

    /// Whether this reminder is scheduled to occur today.
    var occursToday: Bool {
        schedule?.containsToday(startingFrom: date) ?? false
    }
}
