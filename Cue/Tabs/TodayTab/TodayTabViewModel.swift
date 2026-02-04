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
    var today: Date = Date.now.startOfDay
    var todayCalendar: CalendarDay? = nil
    @ObservationIgnored
    private var calendarParsingTask: Task<Void, Never>?
    
    var todayInCalendar: CalendarDay? {
        calendarDay.first(where: { $0.date == today })
    }
    
    func setupCalendarForOneMonth(reminders: [Reminder]) {
        guard !reminders.isEmpty else { return }
        print(#function)
        calendarParsingTask?.cancel()
        calendarParsingTask = Task {
            let days = await CalendarManager.shared.setupCalendarForOneMonthFromToday()
            await MainActor.run { [weak self] in
                self?.calendarDay = days
            }
        }
    }
    
}
