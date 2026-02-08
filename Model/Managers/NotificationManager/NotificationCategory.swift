//
//  NotificationCategory.swift
//  Cue
//
//  Created by Krishna Venkatramani on 07/02/2026.
//

import Foundation

public enum NotificationCategory: String {
    case reminder = "reminder"
}

public enum NotificationReminder {
    case reminder(ReminderModel)
    
    var identifier: String {
        switch self {
        case .reminder(let reminder):
            "\(reminder.title.split(separator: " ").reduce("reminder", { "\($0)_\($1)"}))"
        }
    }
}
