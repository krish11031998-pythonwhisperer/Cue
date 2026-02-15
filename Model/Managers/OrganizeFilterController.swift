//
//  OrganizeFilterController.swift
//  Cue
//
//  Created by Krishna Venkatramani on 12/02/2026.
//

import CoreData

public class OrganizeFilterController {
    
    @frozen
    public enum FetchType {
        case all
        case tags([String])
    }
    
    public static let shared: OrganizeFilterController = .init()
    
    nonisolated
    public func fetchReminders(with backgroundContext: NSManagedObjectContext , type: FetchType) async -> [ReminderModel] {
        let reminders: [ReminderModel]
        reminders = await backgroundContext.perform {
            switch type {
            case .all:
                return  Reminder.fetchAll(context: backgroundContext).map { ReminderModel(from: $0) }
            case .tags(let array):
                return Reminder.fetchRemindersWithTags(context: backgroundContext, names: array).map { ReminderModel(from: $0) }
            }
        }
        
        return reminders
    }
    
    nonisolated
    public func fetchReminders<T: Hashable>(with backgroundContext: NSManagedObjectContext , type: FetchType, transform: @escaping (ReminderModel) -> T) async -> [T] {
        let trasnformables: [T]
        trasnformables = await backgroundContext.perform { [transform] in
            switch type {
            case .all:
                return  Reminder.fetchAll(context: backgroundContext).compactMap {
                    let reminderModel = ReminderModel(from: $0)
                    return transform(reminderModel)
                }
            case .tags(let array):
                return Reminder.fetchRemindersWithTags(context: backgroundContext, names: array).compactMap {
                    let reminderModel = ReminderModel(from: $0)
                    return transform(reminderModel)
                }
            }
        }
        
        return trasnformables
    }
    
}
