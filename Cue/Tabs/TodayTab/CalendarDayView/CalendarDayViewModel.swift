//
//  CalendarDayViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 27/01/2026.
//

import SwiftUI
import Model
import SFSafeSymbols
import ColorTokensKit
import VanorUI
import CoreData

@Observable
class CalendarDayViewModel {
    
    typealias FocusSessionState = FocusSessonCardState.State.SessionState
    typealias TimelineElement = TimeCompactSwiftUIView.Element
    
    enum TimeOfDay: String, CaseIterable {
        case morning
        case afternoon
        case evening
        
        func timeRange(date: Date = .now) -> Range<Date> {
            let startTime: DateComponents
            let endTime: DateComponents
            switch self {
            case .morning:
                startTime = DateComponents(calendar: .current, year: date.year, month: date.month, day: date.day, hour: 0, minute: 0)
                endTime = DateComponents(calendar: .current, year: date.year, month: date.month, day: date.day, hour: 11, minute: 59)
            case .afternoon:
                startTime = DateComponents(calendar: .current, year: date.year, month: date.month, day: date.day, hour: 12, minute: 0)
                endTime = DateComponents(calendar: .current, year: date.year, month: date.month, day: date.day, hour: 16, minute: 59)
            case .evening:
                startTime = DateComponents(calendar: .current, year: date.year, month: date.month, day: date.day, hour: 17, minute: 0)
                endTime = DateComponents(calendar: .current, year: date.year, month: date.month, day: date.day, hour: 23, minute: 59)
            }
            
            return startTime.date!..<endTime.date!
        }
        
        var title: String {
            switch self {
            case .morning:
                return "Morning"
            case .afternoon:
                return "Afternoon"
            case .evening:
                return "Evening"
            }
        }
        
        var symbol: SFSymbol {
            switch self {
            case .morning:
                return .sunrise
            case .afternoon:
                return .sunMax
            case .evening:
                return .moonStars
            }
        }
        
        var color: LCHColor {
            switch self {
            case .morning:
                let light = Color(hex: "#7FB3D5")
                let dark = Color(hex: "#FFD6A5")
                let color = Color(light: .init(light), dark: .init(dark))
                return .init(color: color)
            case .afternoon:
                return .init(color: .init(hex: "#C8E06F"))
            case .evening:
                let light = Color(hex: "#9A9AA3")
                let dark = Color(hex: "#C9CAD6")
                let color = Color(light: .init(light), dark: .init(dark))
                return .init(color: color)
//                return .init(color: .init(hex: "#F2B880"))
//            case .lateEvening:
//                let light = Color(hex: "#9A9AA3")
//                let dark = Color(hex: "#C9CAD6")
//                let color = Color(light: .init(light), dark: .init(dark))
//                return .init(color: color)
            }
        }
    }
    
    struct Section: Hashable, Identifiable {
        
        struct RowModel: Hashable, Identifiable {
            
            enum Config: Identifiable, Hashable {
                case reminder(ReminderView.Model)
                case focusSession(FocusSessionCardView.Config)
                
                var id: String {
                    switch self {
                    case .reminder(let model):
                        "reminder_\(model.id)"
                    case .focusSession(let config):
                        "focusSession_\(config)"
                    }
                }
            }
            
            var viewConfig: Config
            let reminder: ReminderModel
            
            var id: Int {
                var hasher = Hasher()
                hasher.combine(viewConfig)
                hasher.combine(reminder)
                return hasher.finalize()
            }
        }
        
        let timeOfDay: TimeOfDay
        let reminders: [RowModel]
        
        var id: Int {
            var hasher: Hasher = .init()
            reminders.forEach {
                hasher.combine($0)
            }
            hasher.combine(timeOfDay.color)
            hasher.combine(timeOfDay.title)
            return hasher.finalize()
        }
    }
    
    @ObservationIgnored
    var calendarDate: Date
    @ObservationIgnored
    var store: Store
    var focusSessionCoordinator: FocusSessionCoordinator?
    
    var sections: [Section] = []
    var timelineElements: [TimeCompactSwiftUIView.ElementType] = []
    
    init(calendarDate: Date, store: Store) {
        self.store = store
        self.calendarDate = calendarDate
    }
    
    var ongoingFocusSessionCardState: FocusSessonCardState.State {
        guard let focusSessionCoordinator,
              focusSessionCoordinator.session != nil,
              calendarDate.startOfDay == Date.now.startOfDay else { return .idle }
        
        let state: FocusSessonCardState.State.SessionState
        switch focusSessionCoordinator.state {
        case .idle, .reset:
            state = .idle
        case .pause:
            state = .paused
        case .resume, .start:
            state = .running
        }
        
        return .init(progress: focusSessionCoordinator.progress, sessionState: state)
    }
    
    func sections(calendarDay: CalendarDay) {
        var remindersInDay: [TimeOfDay: [Section.RowModel]] = [:]
        for reminder in calendarDay.reminders {
            if let schedule = reminder.schedule,
               let startTime = DateComponents(calendar: .current,
                                              year: calendarDay.date.year,
                                              month: calendarDay.date.month,
                                              day: calendarDay.date.day,
                                              hour: schedule.hour,
                                              minute: schedule.minute).date {

                let rowModel = rowModel(reminder, calendarDay: calendarDay)
                
                switch startTime {
                case TimeOfDay.morning.timeRange(date: calendarDay.date):
                    remindersInDay[.morning, default: []].append(rowModel)
                case TimeOfDay.afternoon.timeRange(date: calendarDay.date):
                    remindersInDay[.afternoon, default: []].append(rowModel)
                case TimeOfDay.evening.timeRange(date: calendarDay.date):
                    remindersInDay[.evening, default: []].append(rowModel)
                default:
                    break
                }
            }
        }
        
        let sections: [Section] = TimeOfDay.allCases.map { .init(timeOfDay: $0, reminders: remindersInDay[$0] ?? []) }
        self.sections = sections
    }
    
    func loggedReminders(_ loggedReminders: [CalendarDay.LoggedReminder]) {
        var factors: [CGFloat: [TimelineElement]] = [:]
        loggedReminders.forEach { reminder in
            let hour = reminder.date.hours
            let stepIndex: CGFloat = (2/24) * CGFloat(hour / 2)
            let arcElements = TimelineElement(icon: .init(reminder.reminder.icon)!, color: .proSky.backgroundSecondary)
            factors[stepIndex, default: []].append(arcElements)
        }
        
        timelineElements = factors.map { (key, values) in
            if values.count > 1 {
                return .group(values, key)
            } else {
                return .single(values.first!, key)
            }
        }
    }
    
    func rowModel(_ reminder: ReminderModel, calendarDay: CalendarDay) -> Section.RowModel {
        if reminder.focusSession != nil, let config = focusSessionModel(reminder, calendarDay: calendarDay) {
            return .init(viewConfig: .focusSession(config), reminder: reminder)
        } else {
            return .init(viewConfig: .reminder(reminderModels(reminder, calendarDay: calendarDay)), reminder: reminder)
        }
    }
    
    func reminderModels(_ reminder: ReminderModel, calendarDay: CalendarDay) -> ReminderView.Model {
        let tasks: [ReminderView.TaskModel] = reminder.tasks.map { task in
            let icon: Icon = .init(task.icon) ?? .symbol(.circle)
            let isLogged = calendarDay.loggedReminderTasks.reduce(false, { $0 || $1.objectId == task.objectId })
            return .init(title: task.title, icon: icon, isLogged: isLogged) { [weak self] in
                if isLogged {
                    self?.store.deleteTaskLogsFor(at: calendarDay.date, for: task.objectId, completion: nil)
                } else {
                    self?.store.logReminderTask(at: calendarDay.date, for: task.objectId, completion: nil)
                }
            }
        }
        
        let icon: VanorUI.Icon
        if let symbol = reminder.icon.symbol {
            icon = .symbol(.init(rawValue: symbol))
        } else if let emoji = reminder.icon.emoji {
            icon = .emoji(.init(emoji))
        } else {
            icon = .symbol(.circle)
        }
        
        let isLogged = calendarDay.loggedReminders.contains(where: { $0.reminder.objectId == reminder.objectId })
        
        let model: ReminderView.Model = .init(title: reminder.title,
                                              icon: icon,
                                              lightColor: reminder.color.resolved(for: .light),
                                              darkColor: reminder.color.resolved(for: .dark),
                                              time: reminder.schedule?.timeScheduled,
                                              state: .hasLogged(isLogged),
                                              tasks: tasks,
                                              tags: reminder.tags.map { .init(name: $0.name, color: $0.color) }) { [weak self] in
            self?.logReminder(isLoggedBefore: isLogged, date: calendarDay.date, reminder: reminder)
        } deleteReminder: { [weak self] in
            withAnimation(.snappy) {
                self?.store.deleteReminder(reminderID: reminder.objectId)
            }
        }
        
        return model
    }
    
    func focusSessionModel(_ reminder: ReminderModel, calendarDay: CalendarDay) -> FocusSessionCardView.Config? {
        guard let focusSession = reminder.focusSession else { return nil }
        
        let tasks: FocusSessionCardView.Tasks? = {
            guard !reminder.tasks.isEmpty else { return nil }
            let count = reminder.tasks.reduce(0, { (count, task) in
                let hasLogged = calendarDay.loggedReminderTasks.contains(where: { $0.objectId == task.objectId }) ? 1 : 0
                return count + hasLogged
            })
            return .init(tasksCompleted: count, taskCount: reminder.tasks.count)
        }()
        
        var icon: VanorUI.Icon = .unavailableIcon
        if let symbol = reminder.icon.symbol {
            icon = .symbol(.init(rawValue: symbol))
        } else if let emoji = reminder.icon.emoji {
            icon = .emoji(.init(emoji))
        }
        
        var sessionType: FocusSessionType
        switch focusSession.sessionType {
        case .classic:
            sessionType = .classic
        case .pomodoro:
            sessionType = .pomodoro(currentIndex: 0, total: focusSession.sessionCount ?? 0)
        default:
            sessionType = .classic
        }
        
        let actions: FocusSessionCardView.Actions = .init { [weak self] state in
            self?.toggleFocusSessionStates(reminderModel: reminder,
                                           for: .init(reminderFocusSession: focusSession,
                                                      with: reminder),
                                     state: state)
        } logAsCompleted: { [weak self] in
            let isLoggedAsCompleted =  calendarDay.loggedReminders.contains(where: { $0.reminder.objectId == reminder.objectId })
            self?.logReminder(isLoggedBefore: isLoggedAsCompleted, date: calendarDay.date, reminder: reminder)
        }
        
        let sessionAttributes: FocusSessionCardView.SessionAttributes = .init(sessionType: sessionType,
                                                                              alarmSet: focusSession.alarm != .off,
                                                                              blockAppsSet: !(focusSession.blockedApps?.isEmpty ?? true),
                                                                              timeDuration: focusSession.timerDuration,
                                                                              breakDuration: focusSession.breakDuration)
        
        return .init(title: reminder.title,
                     color: reminder.color,
                     icon: icon,
                     date: reminder.schedule?.timeScheduled ?? .now,
                     sessionAttributes: sessionAttributes,
                     tasks: tasks,
                     actions: actions)
    }
    
    
    // MARK: - Private Methods
    
    private func logReminder(isLoggedBefore: Bool, date: Date, reminder: ReminderModel) {
        let dateOfLog: Date
        if date.startOfDay < Date.now.startOfDay {
            dateOfLog = Calendar.current.date(byAdding: .init(hour: reminder.schedule?.hour ?? 0, minute: reminder.schedule?.minute ?? 0), to: date.startOfDay) ?? date.startOfDay
        } else {
            dateOfLog = max(date.startOfDay, min(Date.now, date.endOfDay))
        }
        
        let reminderID = reminder.objectId!
        if !isLoggedBefore {
            store.logReminder(at: dateOfLog, for: reminderID)
        } else {
            store.deleteLogsFor(at: date, for: reminderID)
        }
    }
    
    private func toggleFocusSessionStates(reminderModel: ReminderModel, for focusSession: Model.FocusSessionModel, state: FocusSessionState) {
        switch state {
        case .idle:
            focusSessionCoordinator?.reminderModel = reminderModel
            focusSessionCoordinator?.startWithFocusSessionModel(focusSession)
        case .paused:
            focusSessionCoordinator?.resumeTimer()
        case .running:
            focusSessionCoordinator?.pauseTimer()
        case .stop:
            break
        }
    }
}
