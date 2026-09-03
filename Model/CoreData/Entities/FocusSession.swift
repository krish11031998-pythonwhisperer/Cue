//
//  FocusSession.swift
//  Model
//
//  Created by Krishna Venkatramani on 24/08/2026.
//

import Foundation
import CoreData
import FamilyControls

@objc(FocusSession)
public final class FocusSession: NSManagedObject, CoreDataEntity, Identifiable {
    @NSManaged public var name: String!
    @NSManaged public private(set) var sessionType: NSNumber!
    @NSManaged public private(set) var timerDurationRawValue: NSNumber!
    @NSManaged public private(set) var breakDurationRawValue: NSNumber!
    @NSManaged public private(set) var blockedAppsBox: FamilyActivitySelectionBox?
    @NSManaged public private(set) var alarmRawValue: NSNumber!
    @NSManaged public private(set) var reminder: Reminder?
    @NSManaged public private(set) var sessionCountRawValue: NSNumber?
    @NSManaged public private(set) var imageFilePath: String?

    public var blockedApps: FamilyActivitySelection? {
        get {
            blockedAppsBox?.selection
        }

        set {
            blockedAppsBox = newValue.map { FamilyActivitySelectionBox(selection: $0) }
        }
    }

    public var focusSessionType: FocusSessionKind {
        get {
            .init(rawValue: sessionType.int32Value) ?? .classic
        }

        set {
            sessionType = newValue.rawValue as NSNumber
        }
    }

    public var timerDuration: TimeInterval {
        get {
            timerDurationRawValue!.doubleValue
        }

        set {
            timerDurationRawValue = newValue as NSNumber
        }
    }

    public var breakDuration: TimeInterval {
        get {
            breakDurationRawValue!.doubleValue
        }

        set {
            breakDurationRawValue = newValue as NSNumber
        }
    }

    public var alarm: FocusSessionAlarmOption {
        get {
            .init(rawValue: alarmRawValue.int32Value) ?? .off
        }

        set {
            alarmRawValue = newValue.rawValue as NSNumber
        }
    }

    public var sessionCount: Int? {
        get {
            sessionCountRawValue?.intValue
        }

        set {
            sessionCountRawValue = newValue.map { NSNumber(value: $0) }
        }
    }


    // MARK: - Image

    /// Name of the image file inside the app's images directory.
    /// Stored relative — an absolute container path does not survive a reinstall.
    public var imageFileName: String? {
        imageFilePath
    }

    public func setImageFileName(_ imageFileName: String?) {
        self.imageFilePath = imageFileName
    }


    // MARK: - Create

    static func createFocusSession(context: NSManagedObjectContext, name: String, sessionType: FocusSessionKind, timerDuration: TimeInterval, breakDuration: TimeInterval, blockedApps: FamilyActivitySelection?, alarm: FocusSessionAlarmOption, sessionCount: Int?, imageFileName: String? = nil) -> FocusSession {
        let session = create(context: context)
        session.name = name
        session.focusSessionType = sessionType
        session.timerDuration = timerDuration
        session.breakDuration = breakDuration
        session.blockedApps = blockedApps
        session.alarm = alarm
        session.sessionCount = sessionCount
        session.imageFilePath = imageFileName
        return session
    }

    public func updateProperties(name: String, sessionType: FocusSessionKind, timerDuration: TimeInterval, breakDuration: TimeInterval, blockedApps: FamilyActivitySelection?, alarm: FocusSessionAlarmOption, sessionCount: Int?, imageFileName: String? = nil) {
        self.name = name
        self.focusSessionType = sessionType
        self.timerDuration = timerDuration
        self.breakDuration = breakDuration
        self.blockedApps = blockedApps
        self.alarm = alarm
        self.sessionCount = sessionCount
        self.imageFilePath = imageFileName
    }


    // MARK: - Update

    public func setReminder(_ reminder: Reminder?) {
        self.reminder = reminder
    }


    // MARK: - Delete

    public func delete(context: NSManagedObjectContext) {
        context.delete(self)
        context.saveContext()
    }


    // MARK: - Identifiable

    public var id: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(sessionType)
        hasher.combine(timerDurationRawValue)
        hasher.combine(breakDurationRawValue)
        hasher.combine(alarmRawValue)
        return hasher.finalize()
    }
}
