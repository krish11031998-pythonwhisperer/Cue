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
    
    init(day: CalendarDay) {
        self.init(date: day.date,
                  reminderCount: day.reminders.count,
                  loggedElements: day.loggedReminders
            .prefix(3)
            .compactMap { logged in
                guard let icon = Icon(logged.reminder.icon) else { return nil }
                return .init(icon: icon, color: Color.proSky.baseColor)
            })
    }
    
}
