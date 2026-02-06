//
//  CoreDataEntity.swift
//  Cue
//
//  Created by Krishna Venkatramani on 17/01/2026.
//

import CoreData

public protocol CoreDataEntity: NSManagedObject {
    static func fetch(context: NSManagedObjectContext, for id: NSManagedObjectID) -> Self
    static func fetchAll(context: NSManagedObjectContext) -> [Self]
    static func fetch(context: NSManagedObjectContext, predicate: NSPredicate?, sortDescriptors: [NSSortDescriptor]) -> [Self]?
    static func create(context: NSManagedObjectContext) -> Self
    func delete(context: NSManagedObjectContext)
}

public extension CoreDataEntity where Self: NSManagedObject {
    
    static func fetch(context: NSManagedObjectContext, for id: NSManagedObjectID) -> Self {
        context.object(with: id) as! Self
    }
    
    static func fetchAll(context: NSManagedObjectContext) -> [Self] {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = .init(entityName: "\(Self.self)")
        let objects = try? context.fetch(fetchRequest)
        return objects as? [Self] ?? []
    }
    
    static func create(context: NSManagedObjectContext) -> Self {
        let object = NSEntityDescription.insertNewObject(forEntityName: "\(Self.self)", into: context) as! Self
        return object
    }
    
    static func fetch(context: NSManagedObjectContext, predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) -> [Self]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(NSStringFromClass(Self.self)))
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        return try? context.fetch(fetchRequest) as? [Self]
    }
    
    
    // MARK: - Update
    
    func update(context: NSManagedObjectContext, transform: (Self) -> Void) {
        transform(self)
        context.saveContext()
    }
}
