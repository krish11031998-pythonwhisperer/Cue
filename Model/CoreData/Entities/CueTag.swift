//
//  Tag.swift
//  Cue
//
//  Created by Krishna Venkatramani on 12/02/2026.
//

import CoreData
import UIKit

@objc(CueTag)
public final class CueTag: NSManagedObject, CoreDataEntity {
    
    @NSManaged public private(set) var name: String!
    @NSManaged public private(set) var colorRawValue: String!
    @NSManaged public private(set) var reminders: NSSet!
    
    public var color: UIColor {
        get { .init(hex: colorRawValue) ?? UIColor.systemBlue }
        set { colorRawValue = newValue.toHex() ?? "#FFFFFF" }
    }
    
    var remindersArray: [Reminder] {
        reminders.allObjects as! [Reminder]
    }
    
    // MARK: - Create
    
    public static func createTag(context: NSManagedObjectContext, name: String, color: UIColor) -> CueTag {
        let tag = create(context: context)
        tag.name = name
        tag.colorRawValue = color.toHex() ?? "#FFFFFF"
        return tag
    }
    
    
    // MARK: - Delete
    
    public func delete(context: NSManagedObjectContext) {
        context.delete(self)
    }
    
    
}
