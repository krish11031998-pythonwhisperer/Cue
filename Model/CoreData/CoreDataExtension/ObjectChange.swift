//
//  ObjectChange.swift
//  Cue
//
//  Created by Krishna Venkatramani on 19/01/2026.
//

import CoreData
import Combine
import AsyncAlgorithms

extension NSManagedObjectContext {
    
    public enum ObjectChange<T: NSManagedObject> where T: NSManagedObject {
        case updated(T)
        case deleted
        
        public var object: T? {
            switch self {
            case .updated(let object):
                return object
            case .deleted:
                return nil
            }
        }
    }
    
    enum ChangeType {
        case inserted
        case deleted
        case updated

        var userInfoIDsKey: String {
            switch self {
            case .inserted: return NSInsertedObjectIDsKey
            case .deleted: return NSDeletedObjectIDsKey
            case .updated: return NSUpdatedObjectIDsKey
            }
        }

        var userInfoObjectsKey: String {
            switch self {
            case .inserted: return NSInsertedObjectsKey
            case .deleted: return NSDeletedObjectsKey
            case .updated: return NSUpdatedObjectsKey
            }
        }
    }
    
    enum Event {
        case changed
        case willSave
        case didSave

        var notificationName: Notification.Name {
            switch self {
            case .changed:
                return NSManagedObjectContext.didChangeObjectsNotification
            case .willSave:
                return NSManagedObjectContext.willSaveObjectsNotification
            case .didSave:
                return NSManagedObjectContext.didSaveObjectsNotification
            }
        }
    }
    
    
    /// Returns a publisher which which can be used to observe changes in a specific managed object or its relevant relationships..
    /// The managed object must conform to ObservableManagedObject. This is used to know what relationships we should observe for changes.
    /// The publisher returns a change enum value, which can be either update or deleted. For updates the updated object is included.
    ///
    /// - Returns: A publisher for the managed object.
    func objectChangedPublisher<T: NSManagedObject>(for managedObject: T) -> AnyPublisher<ObjectChange<T>, Never> where T: NSManagedObject {
        let notification = NSManagedObjectContext.didSaveObjectIDsNotification
        let context = self
        let objectID = managedObject.objectID
//        let relationshipsToObserve = managedObject.relationshipsToObserve
        
        return NotificationCenter.default.publisher(for: notification, object: context)
            .compactMap({ (notification) in
                let insertedIDs = (notification.userInfo?[NSInsertedObjectIDsKey] as? Set<NSManagedObjectID>) ?? Set<NSManagedObjectID>()
                let updatedIDs = (notification.userInfo?[NSUpdatedObjectIDsKey] as? Set<NSManagedObjectID>) ?? Set<NSManagedObjectID>()
                let deletedIDs = (notification.userInfo?[NSDeletedObjectIDsKey] as? Set<NSManagedObjectID>) ?? Set<NSManagedObjectID>()
                
                guard !deletedIDs.contains(objectID) else {
                    return .deleted
                }
                
                guard let object = try? context.existingObject(with: objectID) as? T else {
                    // We don't exist in the context anymore.
                    return nil
                }
                
                // Merge all changes and check if our object has changed.
                let changedObjectIDs = updatedIDs
                    .union(insertedIDs)
                
                if changedObjectIDs.contains(objectID) {
                    return .updated(object)
                }
                
                // The object or its relationships haven't changed.
                return nil
            })
            .eraseToAnyPublisher()
    }
    
    /// Creates a publisher that publishes changes to objects of a specific type.
    /// - Parameters:
    ///   - type: The type to observe changes for.
    ///   - changeTypes: The type of changes to observe.
    /// - Returns: The publisher.
    func changesPublisher<T: NSManagedObject>(for type: T.Type,
                                              changeTypes: [ChangeType]) -> AnyPublisher<[([T], ChangeType)], Never> {
        let mergeNotification = NSManagedObjectContext.didMergeChangesObjectIDsNotification
        // The merged changes come from a different context. Therefore we need to fetch them through their object ID.
        let mergePublisher = NotificationCenter.default.publisher(for: mergeNotification, object: self)
            .compactMap({ notification in
                return changeTypes.compactMap({ type -> ([T], ChangeType)? in
                    guard let changes = notification.userInfo?[type.userInfoIDsKey] as? Set<NSManagedObjectID> else {
                        return nil
                    }
                    
                    let objects = changes
                        .filter({ objectID in objectID.entity == T.entity() })
                        .compactMap({ objectID in self.object(with: objectID) as? T })
                    
                    if objects.isEmpty {
                        return nil
                    } else {
                        return (objects, type)
                    }
                })
            })
        
        let didSaveNotification = Event.didSave.notificationName
        // Since the saves are on this context we can use the objects as is.
        let savePublisher = NotificationCenter.default.publisher(for: didSaveNotification, object: self)
            .compactMap({ notification in
                return changeTypes.compactMap({ type -> ([T], ChangeType)? in
                    guard let objectChanges = notification.userInfo?[type.userInfoObjectsKey] as? Set<NSManagedObject> else {
                        return nil
                    }
                    let objects = objectChanges.compactMap { $0 as? T }
                    
                    if objects.isEmpty {
                        return nil
                    } else {
                        return (objects, type)
                    }
                })
            })
        
        let mergedPublisher = Publishers.Merge(mergePublisher, savePublisher)
        return mergedPublisher.eraseToAnyPublisher()
    }
    
    
    // async variant
    func changesStream<T: NSManagedObject>(for type: T.Type,
                                           changeTypes: [ChangeType]) -> AsyncStream<()> {
        let mergeNotification = NSManagedObjectContext.didMergeChangesObjectIDsNotification
        // The merged changes come from a different context. Therefore we need to fetch them through their object ID.
        let mergePublisher: AsyncPublisher<AnyPublisher<(), Never>> = NotificationCenter.default.publisher(for: mergeNotification, object: self)
            .compactMap({ notification in
                return changeTypes.reduce(true, { partialResult, changeType in
                    guard let changes = notification.userInfo?[changeType.userInfoIDsKey] as? Set<NSManagedObjectID> else {
                        return partialResult || false
                    }
                    
                    let objects = changes
                        .filter({ objectID in objectID.entity == T.entity() })
                        .compactMap({ objectID in self.object(with: objectID) as? T })
                    
                    if objects.isEmpty {
                        return partialResult || false
                    } else {
                        return partialResult || true
                    }
                })
            })
            .map({ _ in () })
            .eraseToAnyPublisher()
            .values
        
        let didSaveNotification = Event.didSave.notificationName
        // Since the saves are on this context we can use the objects as is.
        let savePublisher = NotificationCenter.default.publisher(for: didSaveNotification, object: self)
            .compactMap({ notification in
            return changeTypes.reduce(true, { partialResult, changeType in
                guard let changes = notification.userInfo?[changeType.userInfoIDsKey] as? Set<NSManagedObjectID> else {
                    return partialResult || false
                }
                
                let objects = changes
                    .filter({ objectID in objectID.entity == T.entity() })
                    .compactMap({ objectID in self.object(with: objectID) as? T })
                
                if objects.isEmpty {
                    return partialResult || false
                } else {
                    return partialResult || true
                }
            })
        })
        .map({ _ in () })
        .eraseToAnyPublisher()
        .values
        
//        let mergedPublisher = Publishers.Merge(mergePublisher, savePublisher)
        return AsyncStream { continuation in
            Task {
                for await result in merge(mergePublisher, savePublisher) {
                    continuation.yield(())
                }
            }
        }
    }
}
