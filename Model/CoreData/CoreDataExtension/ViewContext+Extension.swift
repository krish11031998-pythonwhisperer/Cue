//
//  ViewContext+Extension.swift
//  Model
//
//  Created by Krishna Venkatramani on 20/01/2026.
//

import Foundation
import CoreData

internal extension NSManagedObjectContext {
    
    func saveContext(with completion: ((Bool) -> Void)? = nil) {
        do {
            try self.save()
            completion?(true)
        } catch {
            print("(ERROR) there was an error while saving context: \(error.localizedDescription)")
            completion?(false)
        }
    }
    
}
