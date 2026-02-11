//
//  User.swift
//  Cue
//
//  Created by Krishna Venkatramani on 11/02/2026.
//

import CoreData

public final class User: NSManagedObject, CoreDataEntity {
    
    @NSManaged public var hapticsEnabledRawValue: NSNumber!
    @NSManaged public var alarmsEnabledRawValue: NSNumber!
    @NSManaged public var notificationRawValue: NSNumber!
    @NSManaged public var id: UUID!
    
    
    public var hapticsEnabled: Bool {
        get { hapticsEnabledRawValue.boolValue }
        set { hapticsEnabledRawValue = newValue as NSNumber }
    }
    
    public var notificationEnabled: Bool {
        get { notificationRawValue.boolValue }
        set { notificationRawValue = newValue as NSNumber }
    }
    
    public var alarmEnabled: Bool {
        get { alarmsEnabledRawValue.boolValue }
        set { alarmsEnabledRawValue = newValue as NSNumber }
    }
    
    // MARK: - Create
    
    public static func createUser(context: NSManagedObjectContext) -> User {
        let user = create(context: context)
        user.id = UUID()
        return user
    }
    
    
    // MARK: - Delete
    
    public func delete(context: NSManagedObjectContext) {
        context.delete(self)
    }
    
}
