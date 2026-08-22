//
//  Model.swift
//  Model
//
//  Created by Krishna Venkatramani on 17/01/2026.
//

import Foundation
import CoreData
internal import UserNotifications
import AlarmKit
import UIKit

@Observable
@MainActor public class Store: NotificationManagerDelegate, AlarmManagerDelegate {
    
    public var user: User? = nil
    public var reminders: [Reminder] = []
    public var tags: [CueTag] = []
    public var presentCreateReminder: Bool = false
    @ObservationIgnored
    public private(set) var notificationManager: NotificationManager
    @ObservationIgnored
    public private(set) var alarmManager: CueAlarmManager
    
    
    public private(set) var loggedTasksToday: Set<ReminderLog> = .init()
    public var viewContext: NSManagedObjectContext {
        CoreDataManager.shared.persistentContainer.viewContext
    }
    
    public func backgroundContext() -> NSManagedObjectContext {
        CoreDataManager.shared.persistentContainer.newBackgroundContext()
    }
    
    public init() {
        self.notificationManager = .init(context: CoreDataManager.shared.persistentContainer.viewContext)
        self.alarmManager = .init(context: CoreDataManager.shared.persistentContainer.viewContext)
        self.retrieveUser()
        self.reminders = Reminder.fetchAll(context: self.viewContext)
        self.tags = CueTag.fetchAll(context: self.viewContext)
        self.notificationManager.delegate = self
        observingTask()
    }
    
    
    // MARK: - Binding
    
    private func observingTask() {
        let remindersChangeStream: AsyncStream<()> = self.viewContext.changesStream(for: Reminder.self, changeTypes: [.inserted, .deleted, .updated])
        let reminderTasksChangeStream: AsyncStream<()> = self.viewContext.changesStream(for: ReminderTask.self, changeTypes: [.inserted, .deleted, .updated])
        let tagsChangeStream: AsyncStream<()> = self.viewContext.changesStream(for: CueTag.self, changeTypes: [.inserted, .deleted, .updated])
        
        Task { @MainActor [weak self] in
            for await _ in remindersChangeStream {
                if let context = self?.viewContext {
                    let reminders = Reminder.fetchAll(context: context)
//                    self?.reminders = self?.deleteRemindersWithWrongDate(reminders) ?? reminders
                    self?.reminders = reminders
                }
            }
        }
        
//        Task { @MainActor [weak self] in
//            for await _ in reminderTasksChangeStream {
//                if let context = self?.viewContext {
//                    let _ = ReminderTask.fetchAll(context: context)
//                }
//            }
//        }
        
        Task { @MainActor [weak self] in
            for await _ in tagsChangeStream {
                if let context = self?.viewContext {
                    let tags = CueTag.fetchAll(context: context)
                    self?.tags = tags
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
    
    
    private func deleteRemindersWithWrongDate(_ reminders: [Reminder]) -> [Reminder] {
        var validReminders: Set<Reminder> = Set(reminders)
        for reminder in reminders where reminder.date.isToday {
            validReminders.remove(reminder)
            reminder.delete(context: viewContext)
        }
        return Array(validReminders)
    }
    
    
    // MARK: - Create User
    
    @MainActor
    func retrieveUser() {
        let users = User.fetchAll(context: viewContext)
        if let firstUser = users.first {
            self.user = firstUser
        } else {
            let user = User.createUser(context: viewContext)
            viewContext.saveContext()
            self.user = user
        }
    }
    
    // MARK: - Reminders
    
    @discardableResult
    public func createReminder(title: String, icon: CueIcon, date: Date, colorName: String, snoozeDuration: TimeInterval, scheduleBuilder: Reminder.ScheduleBuilder?, tasks: [ReminderTaskModel] = [], reminderNotification: ReminderNotification, tags tagModels: [TagModel]) -> Reminder {
        let reminder = Reminder.createReminder(context: viewContext, title: title, icon: icon, colorName: colorName, date: date, snoozeDuration: snoozeDuration, schedule: scheduleBuilder, reminderNotification: reminderNotification)
        
        tasks.forEach { task in
            let reminderTask = fetchReminderTask(task.objectId)
            reminderTask.reminder = reminder
        }
        
        var tags: [CueTag] = []
        for tagModel in tagModels {
            let tag = fetchTag(tagModel.objectId)
            tags.append(tag)
        }
        
        reminder.updateTags(tags)

        viewContext.saveContext()
        NotificationCenter.default.post(.init(reminderEvent: .addedReminder, reminder: .init(from: reminder)))
        return reminder
    }

    public func deleteReminder(reminderID: NSManagedObjectID) {
        let reminder = Reminder.fetch(context: viewContext, for: reminderID)
        let reminderModel = ReminderModel(from: reminder)
        reminder.delete(context: viewContext)
        NotificationCenter.default.post(.init(reminderEvent: .deletedReminder, reminder: reminderModel))
    }

    public func updateReminder(for id: NSManagedObjectID, transform: (Reminder) -> Void) {
        let reminder = Reminder.fetch(context: viewContext, for: id)
        reminder.update(context: viewContext, transform: transform)
        NotificationCenter.default.post(.init(reminderEvent: .updatedReminder, reminder: .init(from: reminder)))
    }
    
    public func updateTasksInReminder(reminder: Reminder, reminderTasks: [ReminderTaskModel], save: Bool) {
        reminder.removeTasks()
        for reminderTask in reminderTasks {
            let task = ReminderTask.fetch(context: viewContext, for: reminderTask.objectId)
            task.reminder = reminder
        }
        if save {
            viewContext.saveContext()
        }
    }
    
    public func updateTagsInReminder(reminder: Reminder, tags: [TagModel], save: Bool) {
        reminder.removeTags()
        var cueTags: [CueTag] = []
        for tagModel in tags {
            let tag = CueTag.fetch(context: viewContext, for: tagModel.objectId)
            cueTags.append(tag)
        }
        reminder.updateTags(cueTags)
        if save {
            viewContext.saveContext()
        }
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
    public func logReminderTask(at date: Date, for reminderTaskID: NSManagedObjectID, completion: ((Bool) -> Void)?) -> ReminderTaskLog {
        let reminderTask = ReminderTask.fetch(context: viewContext, for: reminderTaskID)
        let reminderLog = ReminderTaskLog.createReminderTaskLog(date: date, context: viewContext, reminderTask: reminderTask)
        viewContext.saveContext(with: completion)
        return reminderLog
    }
    
    // Async Variant
    
    @discardableResult
    public func logReminderTask(at date: Date, for reminderTaskID: NSManagedObjectID) async -> Bool {
        return await withCheckedContinuation { continuation in
            logReminderTask(at: date, for: reminderTaskID) { completed in
                continuation.resume(returning: completed)
            }
        }
    }
    
    public func deleteTaskLogsFor(at date: Date, for reminderTaskID: NSManagedObjectID, completion: ((Bool) -> Void)?) {
        let reminderTask = ReminderTask.fetch(context: viewContext, for: reminderTaskID)
        ReminderTaskLog.deleteLog(at: date, reminderTask: reminderTask, context: viewContext)
        viewContext.saveContext(with: completion)
    }

    public func fetchReminderTaskLogs(for reminderID: NSManagedObjectID) -> [ReminderTaskLog] {
        let reminder = Reminder.fetch(context: viewContext, for: reminderID)
        let predicate = NSPredicate(format: "reminderTask.reminder == %@", reminder)
        return ReminderTaskLog.fetch(context: viewContext, predicate: predicate) ?? []
    }
    
    
    // MARK: - Tag
    
    @discardableResult
    public func createTag(name: String, color: UIColor) -> CueTag {
        let tag = CueTag.createTag(context: viewContext, name: name, color: color)
        viewContext.saveContext()
        return tag
    }
    
    public func deleteTag(for id: NSManagedObjectID) {
        let tag = CueTag.fetch(context: viewContext, for: id)
        tag.delete(context: viewContext)
        viewContext.saveContext()
    }
    
    public func fetchTag(_ id: NSManagedObjectID) -> CueTag {
        CueTag.fetch(context: viewContext, for: id)
    }
    
    
    // MARK: - User
    
    public func updateUser(transform: @escaping (User) -> Void) {
        user?.update(context: viewContext, transform: transform)
    }
    
    
    // MARK: - Enable Disable Notifications
    
    func enableNotifications() {
        if notificationManager.authorizationStatus == .notDetermined {
            notificationManager.requestForAuthorizationAfterCheckingNotificationSettings { [weak self] settings in
                guard settings.authorizationStatus == .authorized else { return }
                self?.notificationManager.enableNotifications()
            }
        } else if notificationManager.authorizationStatus != .denied {
            notificationManager.enableNotifications()
        }
    }
    
    func disableNotifications() {
        notificationManager.disableNotifications()
    }
    
    public func updateNotificationsAccess() {
        let currentState = user?.notificationEnabled ?? false
        if currentState {
            disableNotifications()
        } else {
            enableNotifications()
        }
        
        updateUser { user in
            user.notificationEnabled = !user.notificationEnabled
        }
    }
    
    
    // MARK: - Enable Disable Alarms
    
    func enableAlarms() {
        if alarmManager.authorizationState == .notDetermined {
            Task { @MainActor [weak self] in
                await self?.alarmManager.requestForAuthortization()
                guard self?.alarmManager.authorizationState == .authorized else { return }
                self?.alarmManager.enableAlarms()
            }
        } else {
            alarmManager.enableAlarms()
        }
    }
    
    func disableAlarms() {
        alarmManager.removeAllAlarms()
    }
    
    public func updateAlarmsAccess() {
        let currentState = user?.alarmEnabled ?? false
        if currentState {
            disableAlarms()
        } else {
            enableAlarms()
        }
        updateUser { user in
            user.alarmEnabled = !user.alarmEnabled
        }
    }
    
    
    // MARK: - NotificationManagerDelegate
    
    func updateNotificationSettings(_ authorizationStatus: UNAuthorizationStatus) {
        updateUser { user in
            user.notificationEnabled = authorizationStatus == .authorized
        }
    }
    
    func updateAlarmSettings(_ authorizationStatus: AlarmManager.AuthorizationState) {
        updateUser { user in
            user.alarmEnabled = authorizationStatus == .authorized
        }
    }
}

