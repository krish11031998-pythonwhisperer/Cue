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

    public init(name: String, sessionType: FocusSessionKind, timerDuration: TimeInterval, breakDuration: TimeInterval, blockedApps: FamilyActivitySelection?, alarm: FocusSessionAlarmOption) {
        self.name = name
        self.sessionType = sessionType
        self.timerDuration = timerDuration
        self.breakDuration = breakDuration
        self.blockedApps = blockedApps
        self.alarm = alarm
        self.objectId = nil
    }

    public init(from session: FocusSession) {
        self.name = session.name
        self.sessionType = session.focusSessionType
        self.timerDuration = session.timerDuration
        self.breakDuration = session.breakDuration
        self.blockedApps = session.blockedApps
        self.alarm = session.alarm
        self.objectId = session.objectID
    }

    public static func == (lhs: FocusSessionModel, rhs: FocusSessionModel) -> Bool {
        lhs.name == rhs.name &&
        lhs.sessionType == rhs.sessionType &&
        lhs.timerDuration == rhs.timerDuration &&
        lhs.breakDuration == rhs.breakDuration &&
        lhs.blockedApps == rhs.blockedApps &&
        lhs.alarm == rhs.alarm
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(sessionType)
        hasher.combine(timerDuration)
        hasher.combine(breakDuration)
        hasher.combine(alarm)
    }
}
