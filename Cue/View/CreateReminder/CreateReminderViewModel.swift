//
//  CreateReminderViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 18/01/2026.
//

import SwiftUI
import VanorUI
import Model

@Observable
class CreateReminderViewModel {
    
    enum ReminderCalendarPresentation: String, Identifiable {
        case alarmAt = "Alarm At"
        case duration = "Duration"
        case date = "Date"
        case `repeat` = "Repeat"
        case symbolAndColor = "Symbol And Color"
        
        var id: String { self.rawValue }
        
        static var allCases: [ReminderCalendarPresentation] { [.alarmAt, .duration, .date, .repeat] }
    }
    
    enum FullScreenPresentation: String, Identifiable, CaseIterable {
        case symbolSheet = "symbolSheet"
        
        var id: String { self.rawValue }
    }
    
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
    
    @ObservationIgnored
    let store: Store
    @ObservationIgnored
    let reminderSubtasksSession: ReminderSubtaskSession = .init()
    @ObservationIgnored
    var suggestionTask: Task<Void, Never>?
    
    var reminderTitle: String = ""
    var snoozeDuration: Double = 15
    var date: Date = .now
    var timeDate: Date = .now
    var tasks: [CueTask] = []
    var scheduleBuilder: Reminder.ScheduleBuilder = .init(.now)
    var icon: Icon = .symbol(SFSymbol.allSymbols.randomElement()!)
    var color: Color = (Color.proSky.baseColor)
    var isLoadingSuggestions: Bool = false
    var presentation: ReminderCalendarPresentation? = nil
    var fullScreenPresentation: FullScreenPresentation? = nil
    
    init(store: Store) {
        self.store = store
    }
    
    var theme: LCHColor {
        .init(color: color)
    }
    
    // MARK: - Helpers
    
    var canCreateReminder: Bool {
        !self.reminderTitle.isEmpty
    }
    
    var canLoadSuggestions: Bool {
        !self.reminderTitle.isEmpty
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
        case .symbolAndColor:
            fatalError("No Button with title for \(presentation.rawValue)")
        }
    }
    
    var taskViewModels: [ReminderTaskView.Model] {
        var models: [ReminderTaskView.Model] = []
        
        let edit: (Int) -> ((String) -> Void) = { [weak self] index in
            { [weak self] newTaskName in
                self?.tasks[index] = .init(title: newTaskName, icon: .symbol("number.circle.fill"))
            }
        }

        let delete: (Int) -> (() -> Void) = { [weak self] index in
            { [weak self] in
                self?.tasks.remove(at: index)
            }
        }

        for(index, task) in tasks.enumerated() {
            let viewType = ReminderTaskView.ViewType.displayOnly(edit(index), delete(index))
            
            let icon: Icon
            switch task.icon {
            case .emoji(let emoji):
                icon = .emoji(.init(emoji))
            case .symbol(let symbol):
                icon = .symbol(.init(rawValue: symbol))
            default:
                icon = .symbol(.exclamationmark)
            }
            
            let model = ReminderTaskView.Model(taskTitle: task.title,
                                               icon: icon,
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
        self.tasks.append(.init(title: title, icon: .symbol("number.circle.fill")))
    }
    
    func createReminder() {
        scheduleBuilder.hour = timeDate.hours
        scheduleBuilder.minute = timeDate.minutes
        switch icon {
        case .emoji(let emoji):
            store.createReminder(title: reminderTitle, emoji: emoji.char, date: date, scheduleBuilder: scheduleBuilder, tasks: tasks)
        case .symbol(let symbol):
            store.createReminder(title: reminderTitle, symbol: symbol.rawValue, date: date, scheduleBuilder: scheduleBuilder, tasks: tasks)
        }
    }
    
    func suggestionSubtasks() {
        suggestionTask?.cancel()
        isLoadingSuggestions = true
        suggestionTask = Task { [weak self] in
            guard let reminderTitle = self?.reminderTitle else { return }
            let suggestions = await self?.reminderSubtasksSession.suggestionTasks(for: reminderTitle)
            let tasks: [CueTask]? = suggestions?.subTasks.map { suggestion in
                    .init(title: suggestion.title, icon: .emoji(suggestion.icon ))
            }
            
            await MainActor.run { [weak self] in
                if let tasks, !Task.isCancelled {
                    self?.tasks = tasks
                }
                self?.isLoadingSuggestions = false
            }
        }
    }
    
}
