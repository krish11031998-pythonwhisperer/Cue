//
//  TodayTabViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 20/01/2026.
//

import Model
import VanorUI
import SwiftUI
import CoreData

@Observable
class TodayViewModel {
    
    nonisolated private let store: Store
    var calendarDay: [CalendarDay] = []
    var loggedReminders: [Reminder] = []
    var today: CalendarDay? = nil
    @ObservationIgnored
    private var calendarParsingTask: Task<Void, Never>?
    
    init(store: Store) {
        self.store = store
    }
    
    func setupCalendarForOneMonth(reminders: [Reminder]) {
        print(#function)
        guard !reminders.isEmpty else { return }
        calendarParsingTask?.cancel()
        let dayInWeek = Date.now.day
        let start = -dayInWeek - 13
        let end = 7 - dayInWeek + 14
        let reminderModels: [ReminderModel] = reminders.map({ .init(from: $0) })
        calendarParsingTask = Task { [weak self] in
            let dates = Array(start...end)
            let calendarValues: [Date: CalendarDay] = await withTaskGroup(of: CalendarDay?.self) { [reminderModels] group in
                for i in dates {
                    group.addTask { [weak self] in
                        
                        if let date = Calendar.current.date(byAdding: .day, value: i, to: .now)?.startOfDay {
                            let backgroundContext = self?.store.viewContext
                            let loggedReminders = await backgroundContext?.perform { [weak self] in
                                self?.store.fetchReminderLogs(context: backgroundContext,
                                                              from: date.startOfDay,
                                                              to: date.endOfDay).map({ ReminderModel(from: $0.reminder )})
                            } ?? []
                            return CalendarDay(date: date, reminders: reminderModels, loggedReminders: loggedReminders)
                        } else {
                            return nil
                        }
                    }
                }
                
                var calendayDaysMap: [Date: CalendarDay] = [:]
                for await calendarDay in group {
                    if let calendarDay {
                        calendayDaysMap[calendarDay.date] = calendarDay
                    }
                }
                return calendayDaysMap
            }
            guard !Task.isCancelled else {
                print("(DEBUG) Calendar parsing task was cancelled")
                return
            }
            await MainActor.run { [weak self] in
                let calendarDays = calendarValues.sorted(by: { $0.key < $1.key }).map {
                    if $0.key == Date.now.startOfDay && self?.today != $0.value {
                        self?.today = $0.value
                    }
                    return $0.value
                }
                self?.calendarDay = calendarDays
            }
            
        }
//        if !calendarDay.isEmpty {
//            calendarDay.removeAll()
//        }
//        for i in -14...13 {
//            let date = Calendar.current.date(byAdding: .day, value: i, to: .now)?.startOfDay
//            if let date {
//                let calendarDay = CalendarDay(date: date, reminders: reminders)
//                print("(DEBUG) calendarDay: \(calendarDay.date) - reminders: \(calendarDay.reminders.map(\.title))")
//                self.calendarDay.append(calendarDay)
//                if date == Date.now.startOfDay {
//                    self.today = calendarDay
//                }
//            }
//        }
    }
    
    
    nonisolated
    private func retrieveCalendayDay(date: Date, reminders: [ReminderModel]) async -> CalendarDay? {
        let backgroundContext = self.store.backgroundContext()
        let reminderLogs = await backgroundContext.perform { [weak self] in
            self?.store.fetchReminderLogs(context: backgroundContext, from: date.startOfDay, to: date.endOfDay)
        }
        let loggedReminders = reminderLogs?.map({ ReminderModel(from: $0.reminder) }) ?? []
        
        return CalendarDay(date: date, reminders: reminders, loggedReminders: loggedReminders)
    }
    
}
