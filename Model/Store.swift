//
//  Model.swift
//  Model
//
//  Created by Krishna Venkatramani on 17/01/2026.
//

import Foundation
import CoreData
import AsyncAlgorithms

@Observable
@MainActor public class Store {
    
    public var user: User? = nil
    public var reminders: [Reminder] = []
    public var presentCreateReminder: Bool = false
    @ObservationIgnored
    private var notificationManager: NotificationManager
    
    public var viewContext: NSManagedObjectContext {
        CoreDataManager.shared.persistentContainer.viewContext
    }
    
    public func backgroundContext() -> NSManagedObjectContext {
        CoreDataManager.shared.persistentContainer.newBackgroundContext()
    }
    
    public init() {
        self.notificationManager = .init(context: CoreDataManager.shared.persistentContainer.viewContext)
        self.retrieveUser()
        self.reminders = Reminder.fetchAll(context: self.viewContext)
        observingTask()
    }
    
    
    // MARK: - Binding
    
    private func observingTask() {
        let remindersChangeStream: AsyncStream<()> = self.viewContext.changesStream(for: Reminder.self, changeTypes: [.inserted, .deleted, .updated])
        let reminderTasksChangeStream: AsyncStream<()> = self.viewContext.changesStream(for: ReminderTask.self, changeTypes: [.inserted, .deleted, .updated])
        Task { @MainActor [weak self] in
            for await _ in remindersChangeStream {
                if let context = self?.viewContext {
                    let reminders = Reminder.fetchAll(context: context)
                    self?.reminders = reminders
                }
            }
            
            for await _ in reminderTasksChangeStream {
                if let context = self?.viewContext {
                    let reminderTask = ReminderTask.fetchAll(context: context)
                    print("(DEBUG) reminderTasks: ", reminderTask)
                }
            }
        }
    }
    
    public var hasLoggedReminder: AsyncStream<Void> {
        self.viewContext.changesStream(for: ReminderLog.self, changeTypes: [.inserted, .deleted, .updated])
    }
    
    public var hasLoggedTasks: AsyncStream<Void> {
        self.viewContext.changesStream(for: ReminderTaskLog.self, changeTypes: [.inserted, .deleted, .updated])
    }
    
    
    // MARK: - Create User
    
    @MainActor
    func retrieveUser() {
        let users = User.fetchAll(context: viewContext)
        if let firstUser = users.first {
            self.user = firstUser
        } else {
            let user = User.createUser(context: viewContext)
            self.user = user
        }
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
        NotificationCenter.default.post(name: .addedReminder, object: nil)
        return reminder
    }
    
    public func deleteReminder(reminderID: NSManagedObjectID) {
        let reminder = Reminder.fetch(context: viewContext, for: reminderID)
        reminder.delete(context: viewContext)
        NotificationCenter.default.post(name: .deletedReminder, object: nil)
    }
    
    public func updateReminder(for id: NSManagedObjectID, transform: (Reminder) -> Void) {
        let reminder = Reminder.fetch(context: viewContext, for: id)
        reminder.update(context: viewContext, transform: transform)
        NotificationCenter.default.post(name: .updatedReminder , object: nil)
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
    
    @discardableResult
    public func logReminderTask(at date: Date, for reminderTaskID: NSManagedObjectID) -> ReminderTaskLog {
        let reminderTask = ReminderTask.fetch(context: viewContext, for: reminderTaskID)
        let reminderLog = ReminderTaskLog.createReminderTaskLog(date: date, context: viewContext, reminderTask: reminderTask)
        return reminderLog
    }
    
    public func deleteTaskLogsFor(at date: Date, for reminderTaskID: NSManagedObjectID) {
        let reminderTask = ReminderTask.fetch(context: viewContext, for: reminderTaskID)
        ReminderTaskLog.deleteLog(at: date, reminderTask: reminderTask, context: viewContext)
    }
    
    
    // MARK: - User
    
    public func updateUser(transform: @escaping (User) -> Void) {
        user?.update(context: viewContext, transform: transform)
    }
}
