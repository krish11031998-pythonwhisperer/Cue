//
//  FocusReminderManager.swift
//  Cue
//
//  Created by Krishna Venkatramani on 22/08/2026.
//

import Model
import VanorUI
import Foundation
import CoreData

class FocusStoreManager: StoreCoordinator {
    var reminder: ReminderModel? {
        didSet {
            updateCompletedTasksForReminder()
        }
    }
    var completedTasks: [ReminderTaskModel] = []
    var store: Store?

    var reminderTasks: [ReminderTaskModel] {
        reminder?.tasks ?? []
    }
    
    var sessionAttributes: FocusSessionAttributes? {
        guard let reminder else { return nil }
        return .init(name: reminder.title,
                     color: .init(color: reminder.color),
                     icon: .init(reminder.icon) ?? Icon.symbol(.timer),
                     sessionType: nil,
                     numberOfTasks: reminder.tasks.count)
    }
    
    func saveTask(_ task: ReminderTaskModel) async {
        // Save Task to Store.
        await store?.logReminderTask(at: .now, for: task.objectId)
    }
    
    func logReminder() {
        // Log Reminder to Store.
        guard let reminder else { return }
        store?.logReminder(at: .now, for: reminder.objectId)
    }
    
    
    // MARK: - Private Methods
    
    private func updateCompletedTasksForReminder() {
        guard let reminder, let store else { return }
        let loggedTaskIDs = Set(store.fetchReminderTaskLogs(for: reminder.objectId).map { $0.reminderTask.objectID })
        completedTasks = reminder.tasks.filter { loggedTaskIDs.contains($0.objectId) }
    }
}
