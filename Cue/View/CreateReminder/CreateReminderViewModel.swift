//
//  CreateReminderViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 18/01/2026.
//

import SwiftUI
import VanorUI
import Model
import CoreData
import FoundationModels
internal import AlarmKit

@Observable
class CreateReminderViewModel {
    
    enum ReminderCalendarPresentation: String, Identifiable {
        case alarmAt = "Alarm At"
        case duration = "Duration"
        case date = "Date"
        case `repeat` = "Repeat"
        case iconSelector = "Symbol And Color"
        
        var id: String { self.rawValue }
        
        static var allCases: [ReminderCalendarPresentation] { [.alarmAt, .duration, .date, .repeat] }
    }
    
    enum Presentation: String, Identifiable {
        case tags
        
        var id: String { self.rawValue }
    }
    
    // MARK: Time
    
    struct Time {
        let hour: Int
        let minute: Int
        
        init(hour: Int, minute: Int) {
            self.hour = hour
            self.minute = minute
        }
        
        init(_ date: Date) {
            self.hour = date.hours
            self.minute = date.minutes
        }
        
        var date: Date {
            Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now)!
        }
    }
    
    
    // MARK: - Task
    
    struct CreateReminderTask: Identifiable {
        let title: String
        let icon: Icon
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
    
    @ObservationIgnored
    let store: Store
    @ObservationIgnored
    let reminderSubtasksSession: ReminderSubtaskSession = .init()
    @ObservationIgnored
    var suggestionTask: Task<Void, Never>?
    @ObservationIgnored
    var edittingMode: Bool
    @ObservationIgnored
    var reminderID: NSManagedObjectID?
    
    var imageFrame: CGRect = .zero
    var reminderTitle: String = ""
    var snoozeDuration: Double = 15 * 60
    var reminderNotification: ReminderNotification = .notification
    var date: Date = .now
    var timeDate: Date = .now
    var tasks: [CreateReminderTask] = []
    var tags: [TagModel] = []
    var scheduleBuilder: Reminder.ScheduleBuilder = .init(.now)
    var icon: Icon = .symbol(SFSymbol.allSymbols.randomElement()!)
    var color: Color = (Color.proSky.baseColor)
    var isLoadingSuggestions: Bool = false
    var calendarPresentation: ReminderCalendarPresentation? = nil
    var presentation: Presentation? = nil
    
    init(store: Store) {
        print("(DEBUG) init is called!!!")
        self.store = store
        self.edittingMode = false
        self.reminderID = nil
    }
    
    var theme: LCHColor {
        .init(color: color)
    }
    
    // MARK: - Helpers
    
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
    
    func buttonTitleForElement(_ presentation: ReminderCalendarPresentation) -> String {
        switch presentation {
        case .alarmAt:
            timeString
        case .duration:
            durationString
        case .date:
            dateString
        case .repeat:
            scheduleString
        case .iconSelector:
            fatalError("No Button with title for \(presentation.rawValue)")
        }
    }
    
    var tagString: String? {
        guard !tags.isEmpty else { return nil }
        let tagName = tags.reduce("", {
            if $0.isEmpty {
                return $1.name
            } else {
                return "\($0) • \($1.name)"
            }
        })
        
        return tagName
    }
    
    
    // MARK: - Data Helpers
    
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
                    self?.tasks.remove(at: index)
                }
            }
        }

        for(index, task) in tasks.enumerated() {
            let viewType = ReminderTaskView.ViewType.displayOnly(edit(index), delete(index)) { [weak self] in
                print("(DEBUG) tapped on icon!")
                self?.calendarPresentation = .iconSelector
            }
        
            let model = ReminderTaskView.Model(taskTitle: task.title,
                                               icon: task.icon,
                                               viewType: viewType,
                                               action: nil)
            models.append(model)
        }
        return models
    }
    
    
    // MARK: - Methods
    
    func updateScheduleBuilder(_ scheduleBuilder: Reminder.ScheduleBuilder) {
        self.scheduleBuilder.intervalWeek = scheduleBuilder.intervalWeek
        self.scheduleBuilder.weekdays = scheduleBuilder.weekdays
        self.scheduleBuilder.dates = scheduleBuilder.dates
    }
    
    func addTask(title: String) {
        self.tasks.append(.init(title: title, icon: .emoji(Emoji.all.randomElement()!), objectID: nil))
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
    
    
    // MARK: - Setup Based on Mode
    
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
