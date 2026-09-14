//
//  UserModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 13/09/2026.
//

import CoreData

public struct UserModel: Hashable, Sendable, Identifiable {
    public let objectId: NSManagedObjectID
    public let hapticsEnabled: Bool
    public let notificationEnabled: Bool
    public let alarmEnabled: Bool
    public let proStatus: UserProStatus
    
    public init(objectId: NSManagedObjectID, hapticsEnabled: Bool, notificationEnabled: Bool, alarmEnabled: Bool, proStatus: UserProStatus) {
        self.objectId = objectId
        self.hapticsEnabled = hapticsEnabled
        self.notificationEnabled = notificationEnabled
        self.alarmEnabled = alarmEnabled
        self.proStatus = proStatus
    }
    
    public static func from(_ user: User) -> UserModel {
        .init(objectId: user.objectID,
              hapticsEnabled: user.hapticsEnabled,
              notificationEnabled: user.notificationEnabled,
              alarmEnabled: user.alarmEnabled,
              proStatus: user.proStatus)
    }
    
    public var id: Int {
        var hasher = Hasher()
        hasher.combine(hapticsEnabled)
        hasher.combine(notificationEnabled)
        hasher.combine(alarmEnabled)
        hasher.combine(proStatus)
        return hasher.finalize()
    }
}
