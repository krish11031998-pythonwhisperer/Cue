//
//  NotificationCenter+FocusSessions.swift
//  Model
//
//  Created by Krishna Venkatramani on 25/08/2026.
//

import Foundation

public extension Notification.Name {
    static let addedFocusSession: Notification.Name = .init("addedFocusSession")
    static let deletedFocusSession: Notification.Name = .init("deletedFocusSession")
    static let updatedFocusSession: Notification.Name = .init("updatedFocusSession")
}

public extension Notification {
    private static let focusSessionModelKey = "focusSessionModel"

    init(focusSessionEvent name: Notification.Name, focusSession: FocusSessionModel) {
        self.init(name: name, object: nil, userInfo: [Self.focusSessionModelKey: focusSession])
    }

    var focusSessionModel: FocusSessionModel? {
        userInfo?[Self.focusSessionModelKey] as? FocusSessionModel
    }
}
