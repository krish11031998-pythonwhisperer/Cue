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
        let timeOfDay: TimeOfDay
        let reminders: [ReminderView.Model]
        
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
    
    init(calendarDate: Date, store: Store) {
        self.store = store
        self.calendarDate = calendarDate
    }
    
    func sections(calendarDay: CalendarDay) -> [Section] {
        var remindersInDay: [TimeOfDay: [ReminderView.Model]] = [:]
        for reminder in calendarDay.reminders {
            if let schedule = reminder.schedule,
               let startTime = DateComponents(calendar: .current,
                                              year: calendarDay.date.year,
                                              month: calendarDay.date.month,
                                              day: calendarDay.date.day,
                                              hour: schedule.hour,
                                              minute: schedule.minute).date {
                let reminderViewModel = reminderModels(reminder, calendarDay: calendarDay)
                switch startTime {
                case TimeOfDay.morning.timeRange(date: calendarDay.date):
                    remindersInDay[.morning, default: []].append(reminderViewModel)
                case TimeOfDay.afternoon.timeRange(date: calendarDay.date):
                    remindersInDay[.afternoon, default: []].append(reminderViewModel)
                case TimeOfDay.evening.timeRange(date: calendarDay.date):
                    remindersInDay[.evening, default: []].append(reminderViewModel)
                default:
                    break
                }
            }
        }
        
        let sections: [Section] = TimeOfDay.allCases.map { .init(timeOfDay: $0, reminders: remindersInDay[$0] ?? []) }
        return sections
    }
    
    func reminderModels(_ reminder: ReminderModel, calendarDay: CalendarDay) -> ReminderView.Model {
        let tasks: [ReminderView.TaskModel] = reminder.tasks.map { task in
            let icon: Icon
            switch task.icon {
            case .emoji(let emoji):
                icon = .emoji(.init(emoji))
            case .symbol(let symbol):
                icon = .symbol(.init(rawValue: symbol))
            default:
                icon = .symbol(.circle)
            }
            return .init(title: task.title, icon: icon) {
                print("(DEBUG) logged this \(task.title)")
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
        
        let isLogged = calendarDay.loggedReminders.contains(where: { $0 == reminder })
        
        let model: ReminderView.Model = .init(title: reminder.title,
                                              icon: icon,
                                              theme: Color.proSky,
                                              time: reminder.date,
                                              state: .hasLogged(isLogged),
                                              tasks: tasks) { [weak self] in
            self?.logReminder(isLoggedBefore: isLogged, date: calendarDay.date, reminder: reminder)
        } deleteReminder: { [weak self] in
            withAnimation(.snappy) {
                self?.store.deleteReminder(reminderID: reminder.objectId)
            }
        }
        
        return model
    }
    
    func logReminder(isLoggedBefore: Bool, date: Date, reminder: ReminderModel) {
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
}
