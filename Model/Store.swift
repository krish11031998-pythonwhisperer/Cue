//
//  Model.swift
//  Model
//
//  Created by Krishna Venkatramani on 17/01/2026.
//

import Foundation
import CoreData

@Observable
public class Store {
    
    public var reminders: [Reminder] = []
    var viewContext: NSManagedObjectContext {
        CoreDataManager.shared.persistentContainer.viewContext
    }
    
    public init() {
        self.reminders = Reminder.fetchAll(context: self.viewContext)
        observingTask()
    }
    
    
    // MARK: - Binding
    
    private func observingTask() {
        Task { @MainActor in
            for await _ in self.viewContext.changesStream(for: Reminder.self, changeTypes: [.inserted, .deleted, .updated]) {
                self.reminders = Reminder.fetchAll(context: self.viewContext)
                print("(DEBUG) reminders: ", self.reminders)
            }
        }
    }
    
    
    // MARK: - Reminders
    
    @discardableResult
    public func createReminder(title: String, iconName: String, date: Date, tasks: [CueTask] = []) -> Reminder {
        let reminder = Reminder.createReminder(context: viewContext, title: title, iconName: iconName, date: date, tasks: tasks)
        viewContext.saveContext()
        return reminder
    }
    
}
