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
    @NSManaged public var proStatusRawValue: NSNumber!
    @NSManaged public var proExpiryDate: Date?
    @NSManaged public var proStatusUpdatedAt: Date?
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
    
    /// The last entitlement answer the store gave us, kept across launches.
    ///
    /// Read it through `Store.isProUser` rather than here: an in-place edit to an
    /// `NSManagedObject` never reaches `@Observable`, so the UI watches the `UserModel`
    /// mirror instead.
    public var proStatus: UserProStatus {
        get {
            .init(status: .init(rawValue: proStatusRawValue?.int32Value ?? 0) ?? .unknown,
                  expiryDate: proExpiryDate,
                  updatedAt: proStatusUpdatedAt)
        }
        
        set {
            proStatusRawValue = newValue.status.rawValue as NSNumber
            proExpiryDate = newValue.expiryDate
            proStatusUpdatedAt = newValue.updatedAt
        }
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
