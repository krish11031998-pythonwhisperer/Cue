//
//  TodayTabViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 20/01/2026.
//

import Model
import VanorUI
import SwiftUI

@Observable
class TodayViewModel {
    
    var calendarDay: [CalendarDay] = []
    var today: CalendarDay? = nil
    
    func setupCalendarForOneMonth(reminders: [Reminder]) {
        guard !reminders.isEmpty else { return }
        if !calendarDay.isEmpty {
            calendarDay.removeAll()
        }
        for i in -14...13 {
            let date = Calendar.current.date(byAdding: .day, value: i, to: .now)?.startOfDay
            if let date {
                let calendarDay = CalendarDay(date: date, reminders: reminders)
                print("(DEBUG) calendarDay: \(calendarDay.date) - reminders: \(calendarDay.reminders.map(\.title))")
                self.calendarDay.append(calendarDay)
                if date == Date.now.startOfDay {
                    self.today = calendarDay
                }
            }
        }
    }
    
}
