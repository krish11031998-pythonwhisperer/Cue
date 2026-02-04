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
    
    enum Presentation: Int, Identifiable {
        case addReminder = 0
        
        var id: Int { rawValue }
    }
    
    enum FullScreenSheet: Int, Identifiable {
        case calendar = 0
        
        var id: Int { rawValue }
    }
    
    var presentation: Presentation? = nil
    var fullScreenSheet: FullScreenSheet? = nil
    var topPadding: CGFloat = .zero
    var calendarDay: [CalendarDay] = []
    var loggedReminders: [Reminder] = []
    var todayInCalendar: CalendarDay? = nil
    var today: Date = Date.now.startOfDay
    @ObservationIgnored
    private var calendarParsingTask: Task<Void, Never>?
    
    
    func setupCalendarForOneMonth(reminders: [Reminder]) {
        guard !reminders.isEmpty else { return }
        print(#function)
        calendarParsingTask?.cancel()
        calendarParsingTask = Task {
            let days = await CalendarManager.shared.setupCalendarForOneMonthFromToday()
            await MainActor.run { [weak self] in
                self?.updateTodayInCalendar(days.first(where: { $0.date.startOfDay == Date.now.startOfDay }))
                self?.calendarDay = days
            }
        }
    }
    
    @MainActor
    private func updateTodayInCalendar(_ today: CalendarDay?) {
        if self.todayInCalendar == nil {
            print("(DEBUG) todayInCalendar is nil, setting it")
            self.todayInCalendar = today
        }
    }
    
}
