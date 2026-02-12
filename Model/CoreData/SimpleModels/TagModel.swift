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
    
    public init(id: NSManagedObjectID, name: String, color: Color) {
        self.objectId = id
        self.name = name
        self.color = color
    }
    
    public init(id: NSManagedObjectID, name: String, color: UIColor) {
        self.objectId = id
        self.name = name
        self.color = .init(color)
    }
    
    public static func from(_ tag: CueTag) -> TagModel {
        self.init(id: tag.objectID, name: tag.name, color: tag.color)
    }
    
    
    public var id: Int {
        var hasher = Hasher()
        hasher.combine(name)
        hasher.combine(color)
        return hasher.finalize()
    }
    
}
