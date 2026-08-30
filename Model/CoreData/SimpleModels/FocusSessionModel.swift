//
//  FocusSessionModel.swift
//  Model
//
//  Created by Krishna Venkatramani on 24/08/2026.
//

import Foundation
import CoreData
import FamilyControls

public struct FocusSessionModel: Hashable, @unchecked Sendable {
    public let objectId: NSManagedObjectID!
    public let name: String
    public let sessionType: FocusSessionKind
    public let timerDuration: TimeInterval
    public let breakDuration: TimeInterval
    public let blockedApps: FamilyActivitySelection?
    public let alarm: FocusSessionAlarmOption
    public let sessionCount: Int?
    public let reminder: ReminderModel?

    public init(name: String, sessionType: FocusSessionKind, timerDuration: TimeInterval, breakDuration: TimeInterval, blockedApps: FamilyActivitySelection?, alarm: FocusSessionAlarmOption, sessionCount: Int?, reminder: ReminderModel?) {
        self.name = name
        self.sessionType = sessionType
        self.timerDuration = timerDuration
        self.breakDuration = breakDuration
        self.blockedApps = blockedApps
        self.alarm = alarm
        self.sessionCount = sessionCount
        self.reminder = reminder
        self.objectId = nil
    }

    public init(from session: FocusSession) {
        self.name = session.name
        self.sessionType = session.focusSessionType
        self.timerDuration = session.timerDuration
        self.breakDuration = session.breakDuration
        self.blockedApps = session.blockedApps
        self.alarm = session.alarm
        self.sessionCount = session.sessionCount
        self.reminder = session.reminder.map { ReminderModel(from: $0) }
        self.objectId = session.objectID
    }

    public static func == (lhs: FocusSessionModel, rhs: FocusSessionModel) -> Bool {
        lhs.name == rhs.name &&
        lhs.sessionType == rhs.sessionType &&
        lhs.timerDuration == rhs.timerDuration &&
        lhs.breakDuration == rhs.breakDuration &&
        lhs.blockedApps == rhs.blockedApps &&
        lhs.alarm == rhs.alarm &&
        lhs.sessionCount == rhs.sessionCount &&
        lhs.reminder == rhs.reminder
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(sessionType)
        hasher.combine(timerDuration)
        hasher.combine(breakDuration)
        hasher.combine(alarm)
        hasher.combine(sessionCount)
        hasher.combine(reminder)
    }
}


extension FocusSessionModel: Identifiable {
    public var id: Int {
        hashValue
    }
}


public extension FocusSessionModel {
    static func deepFocus() -> FocusSessionModel {
        .init(name: "Deep Focus", sessionType: .classic, timerDuration: 45 * 60, breakDuration: 5 * 60, blockedApps: nil, alarm: .endOfSession, sessionCount: nil, reminder: nil)
    }

    static func studySprint() -> FocusSessionModel {
        .init(name: "Study Sprint", sessionType: .pomodoro, timerDuration: 25 * 60, breakDuration: 5 * 60, blockedApps: nil, alarm: .betweenSessions, sessionCount: 4, reminder: nil)
    }

    static func quickBreakTimer() -> FocusSessionModel {
        .init(name: "Quick Break Timer", sessionType: .classic, timerDuration: 10 * 60, breakDuration: 0, blockedApps: nil, alarm: .off, sessionCount: nil, reminder: nil)
    }

    static func eveningWindDown() -> FocusSessionModel {
        .init(name: "Evening Wind Down", sessionType: .pomodoro, timerDuration: 30 * 60, breakDuration: 10 * 60, blockedApps: nil, alarm: .endOfSession, sessionCount: 2, reminder: nil)
    }

    static func creativeWriting() -> FocusSessionModel {
        .init(name: "Creative Writing", sessionType: .classic, timerDuration: 50 * 60, breakDuration: 10 * 60, blockedApps: nil, alarm: .endOfSession, sessionCount: nil, reminder: nil)
    }

    static func workoutIntervals() -> FocusSessionModel {
        .init(name: "Workout Intervals", sessionType: .pomodoro, timerDuration: 15 * 60, breakDuration: 3 * 60, blockedApps: nil, alarm: .betweenSessions, sessionCount: 5, reminder: nil)
    }

    static func workout() -> FocusSessionModel {
        .init(name: "Workout", sessionType: .classic, timerDuration: 30 * 60, breakDuration: 0, blockedApps: nil, alarm: .endOfSession, sessionCount: nil, reminder: .exampleOne())
    }

    static func designing() -> FocusSessionModel {
        .init(name: "Designing", sessionType: .classic, timerDuration: 60 * 60, breakDuration: 10 * 60, blockedApps: nil, alarm: .off, sessionCount: nil, reminder: .exampleThree())
    }

    static func run() -> FocusSessionModel {
        .init(name: "Run", sessionType: .classic, timerDuration: 25 * 60, breakDuration: 0, blockedApps: nil, alarm: .endOfSession, sessionCount: nil, reminder: .exampleFour())
    }

    static let allExamples: [FocusSessionModel] = [
        .deepFocus(), .studySprint(), .quickBreakTimer(), .eveningWindDown(),
        .creativeWriting(), .workoutIntervals(), .workout(), .designing(), .run()
    ]
}
