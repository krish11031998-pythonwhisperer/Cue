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
    var today: Date = Date.now.startOfDay
    var todayCalendar: CalendarDay? = nil
    @ObservationIgnored
    private var calendarParsingTask: Task<Void, Never>?
    
    init(store: Store) {
        self.store = store
    }
    
    var todayInCalendar: CalendarDay? {
        calendarDay.first(where: { $0.date == today })
    }
    
    func setupCalendarForOneMonth(reminders: [Reminder]) {
        print(#function)
        guard !reminders.isEmpty else { return }
        calendarParsingTask?.cancel()
        let dayInWeek = Date.now.day
        let start = -dayInWeek - 13
        let end = 7 - dayInWeek + 14
        
        calendarParsingTask = Task { [weak self] in
            let dates = Array(start...end)
            guard !Task.isCancelled else { return }
            
            let backgroundContext = self?.store.backgroundContext()
            guard let backgroundContext else { return }

            let reminderModels = await self?.fetchReminders(backgroundContext: backgroundContext) ?? []
            let calendarValues = await self?.fetchCalendarDay(backgroundContext: backgroundContext, dates: dates, reminderModels: reminderModels)

            
            guard !Task.isCancelled else {
                print("(DEBUG) Calendar parsing task was cancelled")
                return
            }
            
            await MainActor.run { [weak self] in
                let calendarDays = calendarValues?.sorted(by: { $0.key < $1.key }).map {
                    if $0.key == Date.now.startOfDay && self?.todayCalendar == nil {
                        self?.todayCalendar = $0.value
                    }
                    return $0.value
                }
                if let calendarDays {
                    self?.calendarDay = calendarDays
                }
            }
            
        }
    }
    
    
    nonisolated
    private func fetchReminders(backgroundContext: NSManagedObjectContext) async -> [ReminderModel] {
        let reminders: [Reminder] = await backgroundContext.perform {
            Reminder.fetchAll(context: backgroundContext)
        }
        
        return reminders.map { .init(from: $0) }
    }
    
    nonisolated
    private func fetchCalendarDay(backgroundContext: NSManagedObjectContext, dates: [Int], reminderModels: [ReminderModel]) async -> [Date: CalendarDay] {
        let calendarValues: [Date: CalendarDay] = await withTaskGroup(of: CalendarDay?.self) { group in
            for i in dates {
                group.addTask { [weak self] in
                    guard !Task.isCancelled else { return nil }
                    let date = Calendar.current.date(byAdding: .day, value: i, to: .now)!.startOfDay
                    if let self {
                        return await self.retrieveCalendayDay(backgroundContext: backgroundContext, date: date, reminders: reminderModels)
                    } else {
                        return .init(date: date, reminders: reminderModels, loggedReminders: [])
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
        
        return calendarValues
    }
    
    nonisolated
    private func retrieveCalendayDay(backgroundContext: NSManagedObjectContext, date: Date, reminders: [ReminderModel]) async -> CalendarDay {
        let reminderLogs = await backgroundContext.perform {
            ReminderLog.fetchReminderLogsWithinTimeRange(context: backgroundContext, startTime: date.startOfDay, endTime: date.endOfDay)
        }
        
        let loggedReminders = reminderLogs.map { ReminderModel(from: $0.reminder) }
        
        return CalendarDay(date: date, reminders: reminders, loggedReminders: loggedReminders)
    }
    
}
