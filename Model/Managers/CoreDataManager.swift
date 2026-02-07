//
//  CoreDataManager.swift
//  Cue
//
//  Created by Krishna Venkatramani on 17/01/2026.
//

import Foundation
import CoreData

typealias Callback = () -> Void

extension NSPersistentContainer {
    public convenience init(name: String, bundle: Bundle) {
        guard let modelURL = bundle.url(forResource: name, withExtension: "momd") else { fatalError("Unable to located Core Data model") }
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else { fatalError("Unable to create managed object model")}
        self.init(name: name, managedObjectModel: mom)
    }
}

class CoreDataManager {
    
    static let shared: CoreDataManager = .init()
    private(set) var persistentContainer: NSPersistentContainer!
    
    private init() {
        setupContainer()
        #warning("Add Transformers here")
        CueIconTransformer.register()
    }
    
    static var storeURL: URL {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("Could not find url for Document directory")
        }
        
        return documentsURL.appendingPathComponent("Cue.sqlite")
    }
    
    private func setupContainer() {
        let bundle = Bundle(for: type(of: self))
        let description = NSPersistentStoreDescription(url: Self.storeURL)
        let persistantContainer = NSPersistentContainer(name: "Cue", bundle: bundle)
        persistantContainer.persistentStoreDescriptions = [description]
        
        persistantContainer.loadPersistentStores { description, error in
            guard error == nil else {
                fatalError("Failed to load CoreData stack: \(error!)")
            }
            self.persistentContainer = persistantContainer
        }
    }
    
    
    // MARK: - Background Context
    
    func retrieveBackgroundContext() -> NSManagedObjectContext {
        persistentContainer.newBackgroundContext()
    }
    
    
    // MARK: - Read
    
    func fetch<T: NSManagedObject>(for id: NSManagedObjectID) -> T? {
        guard let viewContext = persistentContainer?.viewContext else { return nil }
        return viewContext.object(with: id) as? T
    }
    
    func fetch<T: NSManagedObject>(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) -> [T]? {
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(NSStringFromClass(T.self)))
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        return try? persistentContainer?.viewContext.fetch(fetchRequest) as? [T]
    }
    
    func fetchOnBackground<T: NSManagedObject>(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = [], completion: @escaping (Result<[T], Error>) -> Void) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(NSStringFromClass(T.self)))
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        guard let persistentContainer else {
            fatalError("Persistent Container is nil")
        }
        
        persistentContainer.performBackgroundTask { context in
            guard let results = try? context.fetch(fetchRequest) as? [T] else {
                completion(.failure(NSError(domain: "Result was not casted to :\(T.self)", code: 1001)))
                return
            }
            completion(.success(results))
        }
    }
    
    // Async Version
    func fetchOnBackground<T: NSManagedObject>(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor] = []) async throws -> [T]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(NSStringFromClass(T.self)))
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        
        guard let persistentContainer else {
            fatalError("Persistent Container is nil")
        }
        
        let result: [T]? = try await persistentContainer.performBackgroundTask { context in
            let results = try context.fetch(fetchRequest) as? [T]
            return results
        }
        
        return result
    }
    
    
    // MARK: - Insert Entity
    
    func insertEntityObject<T: NSManagedObject>(completionHandler: Callback? = nil) -> T {
        let entityName = String(NSStringFromClass(T.self))
        let object = NSEntityDescription.insertNewObject(forEntityName: entityName, into: persistentContainer.viewContext) as! T
        
        completionHandler?()
        
        return object
    }
    
    
    // MARK: - Delete Entity
    
    func deleteEntity<T: NSManagedObject>(_ value: T, save: Bool = false, completionHandler: Callback? = nil) {
        persistentContainer.viewContext.delete(value)
        if save {
            Self.shared.save(completionHandler: completionHandler)
        } else if let completionHandler {
            completionHandler()
        }
    }
    
    func deleteEntities<T: NSManagedObject>(value: [T], save: Bool = true, completionHandler: Callback?) {
        value.forEach { object in
            persistentContainer.viewContext.delete(object)
        }
        if save {
            Self.shared.save(completionHandler: completionHandler)
        } else {
            completionHandler?()
        }
    }
    
    
    // MARK: - Save
    
    func save(completionHandler: Callback? = nil) {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("Saved!")
                completionHandler?()
            } catch {
                print("(ERROR) Saving Data in NSManagedObjectContext: ", error.localizedDescription)
            }
        }
    }
}
