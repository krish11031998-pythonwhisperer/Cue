//
//  CalendarDayViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 27/01/2026.
//

import SwiftUI
import Model

@Observable
class CalendarDayViewModel {
    
    @ObservationIgnored
    let calendarDay: CalendarDay
    
    init(calendarDay: CalendarDay) {
        self.calendarDay = calendarDay
    }
    
    var expandedReminder: Set<Reminder> = []
    
    func expandReminder(_ reminder: Reminder) {
        if expandedReminder.contains(reminder) {
            self.expandedReminder.remove(reminder)
        } else {
            self.expandedReminder.insert(reminder)
        }
    }
    
    func logReminder(_ reminder: Reminder) {
        print("(DEBUG) tapped on logging Reminder!")
    }
}
