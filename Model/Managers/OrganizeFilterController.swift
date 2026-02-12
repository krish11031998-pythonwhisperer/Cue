//
//  OrganizeFilterController.swift
//  Cue
//
//  Created by Krishna Venkatramani on 12/02/2026.
//

import CoreData

public class OrganizeFilterController {
    
    public enum FetchType {
        case all
        case tags([String])
    }
    
    public static let shared: OrganizeFilterController = .init()
    
    nonisolated
    public func fetchReminders(with backgroundContext: NSManagedObjectContext , type: FetchType) async -> [ReminderModel] {
        let reminders: [Reminder]
        switch type {
        case .all:
            reminders = Reminder.fetchAll(context: backgroundContext)
        case .tags(let array):
            reminders = Reminder.fetchRemindersWithTags(context: backgroundContext, names: array)
        }
        
        return reminders.map { ReminderModel(from: $0) }
    }
    
}
