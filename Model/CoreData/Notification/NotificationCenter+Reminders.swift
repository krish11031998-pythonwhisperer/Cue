//
//  NotificationCenter.swift
//  Model
//
//  Created by Krishna Venkatramani on 07/02/2026.
//

import Foundation

public extension Notification.Name {
    static let addedReminder: Notification.Name = .init("addedReminder")
    static let deletedReminder: Notification.Name = .init("deletedReminder")
    static let updatedReminder: Notification.Name = .init("updatedReminder")
}

public extension Notification {
    private static let reminderModelKey = "reminderModel"

    init(reminderEvent name: Notification.Name, reminder: ReminderModel) {
        self.init(name: name, object: nil, userInfo: [Self.reminderModelKey: reminder])
    }

    var reminderModel: ReminderModel? {
        userInfo?[Self.reminderModelKey] as? ReminderModel
    }
}
