//
//  ReminderTaskModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 07/02/2026.
//

import Foundation
import CoreData

public struct ReminderTaskModel: Hashable, Sendable {
    public let title: String
    public let icon: CueIcon
    public let objectId: NSManagedObjectID!
    
    public init(title: String, icon: CueIcon) {
        self.title = title
        self.icon = icon
        self.objectId = nil
    }
    
    public init(from reminderTask: ReminderTask) {
        self.title = reminderTask.title
        self.icon = reminderTask.icon
        self.objectId = reminderTask.objectID
    }
}


extension ReminderTaskModel: Identifiable {
    public var id: String {
        "\(title)_\(icon.emoji ?? icon.symbol ?? "no_icon")"
    }
}
