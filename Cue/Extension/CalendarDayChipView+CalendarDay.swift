//
//  CalendarDayChipView+CalendarDay.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/09/2026.
//

import SwiftUI
import VanorUI
import Model


extension CalendarDayChipView.Model {
    
    init(day: CalendarMonth.Day) {
        let loggedElements: [ReminderBubbleView.Element] = day.loggedReminders
            .compactMap { logged in
                guard let icon = Icon(logged.reminder.icon) else { return nil }
                return .init(icon: icon, color: logged.reminder.color)
            }
        
        self.init(date: day.date,
                  remainderColors: day.reminders.map(\.color),
                  loggedElements: loggedElements)
    }
    
}
