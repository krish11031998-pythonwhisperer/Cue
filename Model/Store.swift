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
    public var presentCreateReminder: Bool = false
    
    public var viewContext: NSManagedObjectContext {
        CoreDataManager.shared.persistentContainer.viewContext
    }
    
    public func backgroundContext() -> NSManagedObjectContext {
        CoreDataManager.shared.persistentContainer.newBackgroundContext()
    }
    
    public init() {
        self.reminders = Reminder.fetchAll(context: self.viewContext)
        observingTask()
    }
    
    
    // MARK: - Binding
    
    private func observingTask() {
        let remindersChangeStrem = self.viewContext.changesStream(for: Reminder.self, changeTypes: [.inserted, .deleted, .updated])
        Task { @MainActor [weak self] in
            for await _ in remindersChangeStrem {
                if let context = self?.viewContext {
                    self?.reminders = Reminder.fetchAll(context: context)
                    print("(DEBUG) reminders: ", self?.reminders)
                }
            }
            
//            for await _ in reminderLogsChangeStrem {
//                if let context = self?.viewContext {
//                    self?.reminderLogs = ReminderLog.fetchReminderLogsWithinTimeRange(context: context, startTime: Date.now.startOfYear, endTime: Date.now.endOfYear)
//                    print("(DEBUG) reminderLogs: ", self?.reminderLogs)
//                }
//            }
        }
    }
    
    
    public var hasLoggedReminder: AsyncStream<Void> {
        self.viewContext.changesStream(for: ReminderLog.self, changeTypes: [.inserted, .deleted, .updated])
    }
    
    // MARK: - Reminders
    
    @discardableResult
    public func createReminder(title: String, icon: CueIcon, date: Date, scheduleBuilder: Reminder.ScheduleBuilder?, tasks: [ReminderTaskModel] = []) -> Reminder {
        let reminder = Reminder.createReminder(context: viewContext, title: title, icon: icon, date: date, schedule: scheduleBuilder)
        tasks.forEach { task in
            let reminderTask = fetchReminderTask(task.objectId)
            reminderTask.reminder = reminder
        }
        viewContext.saveContext()
        return reminder
    }
    
    public func deleteReminder(reminderID: NSManagedObjectID) {
        let reminder = Reminder.fetch(context: viewContext, for: reminderID)
        reminder.delete(context: viewContext)
    }
    
    public func updateReminder(for id: NSManagedObjectID, transform: (Reminder) -> Void) {
        let reminder = Reminder.fetch(context: viewContext, for: id)
        reminder.update(context: viewContext, transform: transform)
    }
    
    // MARK: - ReminderLogs
    
    public func fetchReminderLogs(context: NSManagedObjectContext? = nil, from start: Date, to end: Date) -> [ReminderLog] {
        let viewContext = context ?? self.viewContext
        return ReminderLog.fetchLogsWithinTimeRange(context: viewContext, startTime: start, endTime: end) as? [ReminderLog] ?? []
    }
    
    @discardableResult
    public func logReminder(at date: Date, for reminderID: NSManagedObjectID) -> ReminderLog {
        let reminder = Reminder.fetch(context: viewContext, for: reminderID)
        let reminderLog = ReminderLog.createReminderLog(date: date, context: viewContext, reminder: reminder)
        return reminderLog
    }
    
    public func deleteLogsFor(at date: Date, for reminderID: NSManagedObjectID) {
        let reminder = Reminder.fetch(context: viewContext, for: reminderID)
        ReminderLog.deleteLog(at: date, reminder: reminder, context: viewContext)
    }
    
    
    // MARK: - ReminderTask
    
    @discardableResult
    public func createReminderTask(title: String, icon: CueIcon) -> ReminderTask {
        let reminderTask = ReminderTask.createTask(context: viewContext, title: title, icon: icon)
        viewContext.saveContext()
        return reminderTask
    }
    
    private func fetchReminderTask(_ reminderTaskID: NSManagedObjectID) -> ReminderTask {
        ReminderTask.fetch(context: viewContext, for: reminderTaskID)
    }
    
    public func updateReminderTask(for id: NSManagedObjectID, transform: (ReminderTask) -> Void) {
        let reminder = ReminderTask.fetch(context: viewContext, for: id)
        reminder.update(context: viewContext, transform: transform)
    }
    
    public func deleteReminderTask(reminderTaskID: NSManagedObjectID) {
        let reminder = ReminderTask.fetch(context: viewContext, for: reminderTaskID)
        reminder.delete(context: viewContext)
    }
}
