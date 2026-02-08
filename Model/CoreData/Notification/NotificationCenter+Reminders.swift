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
