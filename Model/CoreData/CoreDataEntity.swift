//
//  CoreDataEntity.swift
//  Cue
//
//  Created by Krishna Venkatramani on 17/01/2026.
//

import CoreData

internal protocol CoreDataEntity: NSManagedObject {
    static func fetchAll(context: NSManagedObjectContext) -> [Self]
    static func create(context: NSManagedObjectContext) -> Self
    func delete(context: NSManagedObjectContext)
}

extension CoreDataEntity where Self: NSManagedObject {
    static func fetchAll(context: NSManagedObjectContext) -> [Self] {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = .init(entityName: "\(Self.self)")
        let objects = try? context.fetch(fetchRequest)
        return objects as? [Self] ?? []
    }
    
    static func create(context: NSManagedObjectContext) -> Self {
        let object = NSEntityDescription.insertNewObject(forEntityName: "\(Self.self)", into: context) as! Self
        return object
    }
}
