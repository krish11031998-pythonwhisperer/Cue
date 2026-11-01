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
    
    enum FullScreenPresentation: Identifiable {
        case settings
        case focusTimer(ReminderModel?, Set<ReminderTaskModel>, TimeInterval)
        
        var id: Int {
            switch self {
            case .focusTimer:
                return 1
            case .settings:
                return 2
            }
        }
    }
    
    @ObservationIgnored
    var store: Store? {
        didSet {
            guard let store, oldValue == nil else { return }
            observeReminderModels(store)
        }
    }
    var calendarDays: [CalendarDay] = []
    var calendarDayModels: [CalendarDayView.Model] = []
    var loggedReminders: [Reminder] = []
    var today: Date = Date.now.startOfDay
    var fullPresentation: FullScreenPresentation? = nil
    @ObservationIgnored
    private var calendarParsingTask: Task<Void, Never>?
    @ObservationIgnored
    private var updateCurrentCalendarDayTask: Task<Void, Never>?
    
    
    var todayInCalendar: CalendarDay? {
        calendarDays.first(where: { $0.date == today })
    }
    
    var reminderWithTimer: [ReminderModel] {
        guard let todayInCalendar else { return []}
        
        return todayInCalendar.reminders
            .filter({ reminder in
                return !todayInCalendar.loggedReminders.contains(where: { reminder.objectId == $0.reminder.objectId })
            })
    }
    
    private func setupCalendarForOneMonth(reminders: [ReminderModel]) {
        print(#function)
        guard !reminders.isEmpty else { return }
        calendarParsingTask?.cancel()
        calendarParsingTask = Task { [weak self] in
            let calendarValues = await CalendarManager.shared.setupCalendarForOneMonthFromToday()
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run { [weak self] in
                guard calendarValues.isEmpty == false else { return }

                self?.calendarDays = calendarValues
            }
        }
    }
    
    private func updateCurrentCalendarDay() {
        let date = today
        updateCurrentCalendarDayTask?.cancel()
        updateCurrentCalendarDayTask = Task { [weak self] in
            do {
                let currentCalendarDay = try await CalendarManager.shared.setupCalendarDay(for: date)
                
                guard let index = self?.calendarDays.firstIndex(where: { $0.date == date }), !Task.isCancelled else { return }
                
                self?.calendarDays[index] = currentCalendarDay
            } catch {
                print("(ERROR) there was an error while running the `updateCurrentCalendarDayTask`: ", error.localizedDescription)
            }
        }
    }
    
    func reminderForTimerWithTasks(_ reminder: ReminderModel?) -> Set<ReminderTaskModel> {
        guard let reminder, let todayInCalendar else { return [] }
        let loggedTasks = todayInCalendar.loggedReminderTasks
        return Set(reminder.tasks).intersection(Set(loggedTasks))
    }
    
    private func observeReminderModels(_ store: Store) {
        let reminderObservation = Observations { store.reminderModels }
        Task { @MainActor in
            for await reminders in reminderObservation {
                self.setupCalendarForOneMonth(reminders: reminders)
            }
        }

        Task { @MainActor [weak self] in
            for await _ in store.hasLoggedReminder {
                self?.updateCurrentCalendarDay()
            }
        }
    }
    
}
