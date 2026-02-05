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
    public func createReminder(title: String, symbol: String, date: Date, scheduleBuilder: Reminder.ScheduleBuilder?, tasks: [CueTask] = []) -> Reminder {
        let reminder = Reminder.createReminder(context: viewContext, title: title, symbol: symbol, date: date, schedule: scheduleBuilder, tasks: tasks)
        viewContext.saveContext()
        return reminder
    }
    
    @discardableResult
    public func createReminder(title: String, emoji: String, date: Date, scheduleBuilder: Reminder.ScheduleBuilder?, tasks: [CueTask] = []) -> Reminder {
        let reminder = Reminder.createReminder(context: viewContext, title: title, emoji: emoji, date: date, schedule: scheduleBuilder, tasks: tasks)
        viewContext.saveContext()
        return reminder
    }
    
    public func deleteReminder(reminderID: NSManagedObjectID) {
        let reminder = Reminder.fetch(context: viewContext, for: reminderID)
        reminder.delete(context: viewContext)
    }
    
    
    // MARK: - ReminderLogs
    
    public func fetchReminderLogs(context: NSManagedObjectContext? = nil, from start: Date, to end: Date) -> [ReminderLog] {
        let viewContext = context ?? self.viewContext
        return ReminderLog.fetchReminderLogsWithinTimeRange(context: viewContext, startTime: start, endTime: end)
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
    
}
