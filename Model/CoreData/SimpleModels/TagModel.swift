//
//  TagModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 12/02/2026.
//

import CoreData
import SwiftUI

public struct TagModel: Hashable, Sendable, Identifiable {
    public let objectId: NSManagedObjectID
    public let name: String
    public let color: Color
    public let reminderIDs: [NSManagedObjectID]
    
    public init(id: NSManagedObjectID, name: String, color: Color, reminderIDs: [NSManagedObjectID]) {
        self.objectId = id
        self.name = name
        self.color = color
        self.reminderIDs = reminderIDs
    }
    
    public init(id: NSManagedObjectID, name: String, color: UIColor, reminderIDs: [NSManagedObjectID]) {
        self.objectId = id
        self.name = name
        self.color = .init(color)
        self.reminderIDs = reminderIDs
    }
    
    public static func from(_ tag: CueTag) -> TagModel {
        self.init(id: tag.objectID, name: tag.name, color: tag.color, reminderIDs: tag.remindersArray.map { $0.objectID })
    }
    
    public var id: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(color)
        return hasher.finalize()
    }
}

extension Array where Self.Element == TagModel {
    static func setup(from tags: [CueTag]) -> Array<Self.Element> {
        tags.map { cueTag in
            .from(cueTag)
        }
    }
}
