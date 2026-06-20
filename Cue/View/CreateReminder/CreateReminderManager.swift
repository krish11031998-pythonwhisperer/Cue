//
//  CreateReminderManager.swift
//  Cue
//
//  Created by Krishna Venkatramani on 19/05/2026.
//

import Model
import VanorUI
import SwiftUI
import FoundationModels
import CoreData
internal import AlarmKit

struct CreateReminderTask: Identifiable {
    let title: String
    var icon: Icon
    let objectID: NSManagedObjectID?
    
    init(title: String, icon: Icon, objectID: NSManagedObjectID?) {
        self.title = title
        self.icon = icon
        self.objectID = objectID
    }
    
    var id: Int {
        var hasher = Hasher()
        hasher.combine(title)
        hasher.combine(icon)
        return hasher.finalize()
    }
}

protocol CreateReminderManager: AnyObject {
    
    var store: Store { get set }
    var edittingMode: Bool { get set }
    var reminderID: NSManagedObjectID? { get set }
    var reminderTitle: String { get set }
    var snoozeDuration: Double { get set }
    var date: Date { get set }
    var timeDate: Date { get set }
    var tags: [TagModel] { get set }
    var tasks: [CreateReminderTask] { get set }
    var reminderNotification: ReminderNotification { set get }
    var scheduleBuilder: Reminder.ScheduleBuilder { get set }
    var icon: Icon { get set }
    var color: Color { get set }
    var emojiSession: EmojiSession { get set }
    var reminderSubtasksSession: ReminderSubtaskSession { get set }
    var suggestionTask: Task<Void, Never>? { get set }
    var isLoadingSuggestions: Bool { get set }
    
    var canCreateReminder: Bool { get }
    var canLoadSuggestions: Bool { get }
    
    
    // METHODS
    
    func presentIconSheet()
}

extension CreateReminderManager {
    var canCreateReminder: Bool {
        !self.reminderTitle.isEmpty
    }

    var canLoadSuggestions: Bool {
        switch SystemLanguageModel.default.availability {
        case .available:
            return !self.reminderTitle.isEmpty
        
        case .unavailable(let reason):
            return false
        }
    }
    
    var durationString: String {
        String.formattedTimelineInterval(snoozeDuration)
    }
    
    var scheduleString: String {
        guard (scheduleBuilder.intervalWeek == nil && scheduleBuilder.weekdays == nil) || scheduleBuilder.dates == nil else { return "No Repeat"}
        if let datesInMonths = scheduleBuilder.dates {
            let dates = datesInMonths.sorted().reduce("", { $0.isEmpty ? "\($1)." : "\($0), \($1)."})
            return "\(dates) every month"
        } else if let weekdays = scheduleBuilder.weekdays {
            let weekdaysString = weekdays.sorted().reduce("", {
                let weekdaySymbol = Calendar.current.veryShortStandaloneWeekdaySymbols[$1 - 1]
                return $0.isEmpty ? "\(weekdaySymbol)" : "\($0), \(weekdaySymbol)"
            })
            return "\(weekdaysString) every \(scheduleBuilder.intervalWeek == nil ? "week" : "\(scheduleBuilder.intervalWeek!) weeks")"
        } else {
            return "No Repeat"
        }
    }
    
    var dateString: String {
        if date.startOfDay == Date.now.startOfDay {
            return "Today"
        } else if date.startOfDay == Date.now.tomorrow.startOfDay {
            return "Tomorrow"
        } else {
            return date.dateStringFormatter()
        }
    }
    
    var timeString: String {
        timeDate.timeBuilder()
    }
    
    var taskViewModels: [ReminderTaskView.Model] {
        var models: [ReminderTaskView.Model] = []
        
        let edit: (Int) -> ((String) -> Void) = { [weak self] index in
            { [weak self] newTaskName in
                if let task = self?.tasks[index] {
                    self?.tasks[index] = .init(title: newTaskName, icon: task.icon, objectID: task.objectID)
                }
            }
        }

        let delete: (Int) -> (() -> Void) = { [weak self] index in
            { [weak self] in
                let task = self?.tasks[index]
                if let objectID = task?.objectID {
                    self?.store.deleteReminderTask(reminderTaskID: objectID)
                }
                self?.tasks.remove(at: index)
            }
        }

        for(index, task) in tasks.enumerated() {
            let viewType = ReminderTaskView.ViewType.displayOnly(edit(index), delete(index)) { [weak self] in
                print("(DEBUG) tapped on icon!")
//                self?.calendarPresentation = .iconSelector
                self?.presentIconSheet()
            }
        
            let model = ReminderTaskView.Model(taskTitle: task.title,
                                               icon: task.icon,
                                               viewType: viewType,
                                               action: nil)
            models.append(model)
        }
        return models
    }
    
    
    // Helper Methods
    
    func updateScheduleBuilder(_ scheduleBuilder: Reminder.ScheduleBuilder) {
        self.scheduleBuilder.intervalWeek = scheduleBuilder.intervalWeek
        self.scheduleBuilder.weekdays = scheduleBuilder.weekdays
        self.scheduleBuilder.dates = scheduleBuilder.dates
    }
    
    func addTask(title: String) {
        self.tasks.append(.init(title: title, icon: .symbol(.progressIndicator), objectID: nil))
        Task {
            let emoji = await emojiSession.generateEmoji(for: title)
            
            if let firstIndex = self.tasks.firstIndex(where: { $0.title == title }) {
                self.tasks[firstIndex].icon = .emoji(emoji)
            }
        }
    }
    
    
    // Create SubTasks
    
    func suggestionSubtasks() {
        suggestionTask?.cancel()
        isLoadingSuggestions = true
        suggestionTask = Task { [weak self] in
            guard let reminderTitle = self?.reminderTitle else { return }
            let suggestions = await self?.reminderSubtasksSession.suggestionTasks(for: reminderTitle)
            let tasks: [CreateReminderTask]? = suggestions?.subTasks.map { suggestion in
                    .init(title: suggestion.title, icon: .emoji(.init(suggestion.icon)), objectID: nil)
            }
            
            await MainActor.run { [weak self] in
                if let tasks, !Task.isCancelled {
                    self?.tasks = tasks
                }
                self?.isLoadingSuggestions = false
            }
        }
    }
    
    func createReminder() {
        scheduleBuilder.hour = timeDate.hours
        scheduleBuilder.minute = timeDate.minutes
        if edittingMode, let reminderID {
            var reminderTaskModels: [ReminderTaskModel] = []
            tasks.forEach { task in
                if let objectID = task.objectID {
                    store.updateReminderTask(for: objectID) { reminderTask in
                        reminderTask.updateProperties(title: task.title, icon: .from(task.icon))
                        reminderTaskModels.append(.init(from: reminderTask))
                    }
                } else {
                    let reminderTask = store.createReminderTask(title: task.title, icon: .from(task.icon))
                    reminderTaskModels.append(.init(from: reminderTask))
                }
            }
            
            #warning("Update this when adding tags")
            store.updateReminder(for: reminderID) { reminder in
                reminder.updateProperties(title: reminderTitle,
                                          icon: .from(icon),
                                          date: date,
                                          snoozeDuration: snoozeDuration,
                                          scheduleBuilder: scheduleBuilder,
                                          reminderNotification: reminderNotification)
                if reminder.tasks.count != reminderTaskModels.count {
                    store.updateTasksInReminder(reminder: reminder, reminderTasks: reminderTaskModels, save: false)
                }
                store.updateTagsInReminder(reminder: reminder, tags: tags, save: true)
            }
        } else {
            let reminderTasks = tasks.map { task in
                let task = store.createReminderTask(title: task.title, icon: .from(task.icon))
                return ReminderTaskModel(from: task)
            }
            
            #warning("Update this when adding tags")
            store.createReminder(title: reminderTitle,
                                 icon: .from(icon),
                                 date: date,
                                 snoozeDuration: snoozeDuration,
                                 scheduleBuilder: scheduleBuilder,
                                 tasks: reminderTasks,
                                 reminderNotification: reminderNotification,
                                 tags: tags)
        }
    }
    
    func updateBasedOnMode(reminderModel: ReminderModel) {
        self.reminderTitle = reminderModel.title
        self.date = reminderModel.date
        if let schedule = reminderModel.schedule {
            self.timeDate = Calendar.current.date(bySettingHour: schedule.hour, minute: schedule.minute, second: 0, of: reminderModel.date) ?? .now
            self.scheduleBuilder = .init(hour: schedule.hour, minute: schedule.minute, intervalWeek: schedule.intervalWeeks, weekdays: schedule.weekdays, dates: schedule.calendarDates)
        }
        self.tasks = reminderModel.tasks.map { .init(title: $0.title, icon: .init($0.icon)!, objectID: $0.objectId) }
        self.icon = .init(reminderModel.icon) ?? .symbol(SFSymbol.allSymbols.randomElement()!)
        self.reminderID = reminderModel.objectId
        self.reminderNotification = reminderModel.notificationType
        self.tags = reminderModel.tags
        self.edittingMode = true
    }
    
    
    // MARK: - Notification Management
    
    func checkForPermissionForSendingNotification() {
        store.notificationManager.requestForAuthorizationAfterCheckingNotificationSettings()
    }
    
    
    // MARK: - Alarm Management
    
    func checkForPermissionForSettingAlarm() {
        guard store.alarmManager.authorizationState == .notDetermined else { return }
        Task {
            await store.alarmManager.requestForAuthortization()
        }
    }
}

