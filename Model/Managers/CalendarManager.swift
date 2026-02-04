//
//  CalendarManager.swift
//  Model
//
//  Created by Krishna Venkatramani on 03/02/2026.
//

import Foundation
import CoreData

public class CalendarManager {
    
    public static let shared = CalendarManager()
    
    public func setupCalendarForOneMonthFromToday() async -> [CalendarDay] {
        let dayInWeek = Date.now.day
        let start = -dayInWeek - 13
        let end = 7 - dayInWeek + 14
        
        let dates = Array(start...end).map { i in
            return Calendar.current.date(byAdding: .day, value: i, to: .now)!.startOfDay
        }
        guard !Task.isCancelled else { return []}
        
        let calendarDays = await self.fetchCalendarDays(for: dates)
        
        return calendarDays
    }
    
    public func setupCalendarForOneYearFromNow() async -> [CalendarDay] {
        let startOfYear = Date.now.startOfYear
        let endOfYear = startOfYear.endOfYear
        
        var dates: [Date] = []
        var currentDate = startOfYear
        while currentDate != endOfYear {
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!.startOfDay
        }
        
        guard !Task.isCancelled else { return [] }
        
        let calendarDays = await self.fetchCalendarDays(for: dates)
        
        return calendarDays
    }
    
    public func setupCalendayDaysInCurrentYear(month: Int) async -> [CalendarDay] {
        var dateComponents = Calendar.current.dateComponents([.timeZone, .day, .month, .year], from: Date.now)
        dateComponents.month = month
        dateComponents.day = 1
        let date = Calendar.current.date(from: dateComponents)
        guard let date,
              !Task.isCancelled else { return [] }
        
        var dates: [Date] = []
        var currentDate = date
        while currentDate <= date.endOfMonth {
            dates.append(currentDate)
            currentDate = Calendar.current.date(byAdding: .day, value: 1, to: currentDate)!.startOfDay
        }
        
        let calendarDays = await self.fetchCalendarDays(for: dates)
        
        guard !Task.isCancelled else { return [] }
        
        return calendarDays
    }
    
    nonisolated
    private func fetchCalendarDays(for dates: [Date]) async -> [CalendarDay] {
        let background = CoreDataManager.shared.retrieveBackgroundContext()
        
        let reminders = await self.fetchReminders(backgroundContext: background)
        let calendarValues = await self.fetchCalendarDay(backgroundContext: background, dates: dates, reminderModels: reminders)
        
        guard !Task.isCancelled else {
            print("(DEBUG) Calendar parsing task was cancelled")
            return []
        }
        
        let calendarDays = calendarValues.sorted(by: { $0.key < $1.key }).map {
            return $0.value
        }
        
        return calendarDays
    }
    
    nonisolated
    private func fetchReminders(backgroundContext: NSManagedObjectContext) async -> [ReminderModel] {
        let reminders: [Reminder] = await backgroundContext.perform {
            Reminder.fetchAll(context: backgroundContext)
        }
        
        return reminders.map { .init(from: $0) }
    }
    
    nonisolated
    private func fetchCalendarDay(backgroundContext: NSManagedObjectContext, dates: [Date], reminderModels: [ReminderModel]) async -> [Date: CalendarDay] {
        let calendarValues: [Date: CalendarDay] = await withTaskGroup(of: CalendarDay?.self) { group in
            for date in dates {
                group.addTask { [weak self] in
                    guard !Task.isCancelled else { return nil }
//                    let date = Calendar.current.date(byAdding: .day, value: i, to: .now)!.startOfDay
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
