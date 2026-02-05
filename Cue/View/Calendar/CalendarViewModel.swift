//
//  CalendarViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 03/02/2026.
//

import Foundation
import Model
import VanorUI
import SwiftUI

@Observable
class CalendarViewModel {
    
    struct Section: Identifiable {
        let month: Int
        let days: [CalendarDay]
        
        var id: Int {
            month
        }
        
        var firstDayInMonth: Int {
            guard let firstDay = days.first else {
                fatalError("Must have a first Day!")
            }
            
            return firstDay.date.weekDayValue
        }
    }
    
    @ObservationIgnored
    private var calendarDayTask: Task<Void, Never>?
    
    var calendarData: [Section] = []
    
    func fetchCalendarSection() {
        calendarDayTask?.cancel()
        calendarDayTask = Task {
            let monthCount = Calendar.current.monthSymbols.count
            let months = Array(1...monthCount)
            
            let sections: [Section] = await withTaskGroup(of: Section.self) { group in
                for i in months {
                    group.addTask {
                        let calendarDays = await CalendarManager.shared.setupCalendayDaysInCurrentYear(month: i)
                        return Section(month: i, days: calendarDays)
                    }
                }
                
                var sections: [Section] = []
                for await section in group {
                    sections.append(section)
                }
                
                return sections.sorted(by: { $0.month < $1.month })
            }
            
            await MainActor.run { [weak self] in
                self?.calendarData = sections
            }
        }
    }
    
    
    func buildBubbleConfig(for day: CalendarDay) -> ReminderBubbleView.ElementType? {
        guard !day.loggedReminders.isEmpty else { return nil }
        let firstThreeLoggedReminders = day.loggedReminders.prefix(3)
        
        func getIcon(_ cueIcon: CueIcon) -> Icon {
            if let symbol = cueIcon.symbol {
                return .symbol(.init(rawValue: symbol))
            } else if let emoji = cueIcon.emoji {
                return .emoji(.init(emoji))
            } else {
                fatalError("No Icon!")
            }
        }
        
        
        switch firstThreeLoggedReminders.count {
        case 2, 3:
            return .group(firstThreeLoggedReminders.map({ .init(icon: getIcon($0.icon), color: Color.proSky.baseColor)}))
        case 1:
            return .single(.init(icon: getIcon(firstThreeLoggedReminders.first!.icon), color: Color.proSky.baseColor))
        default:
            fatalError("Shouldn't end up here!")
            
        }
    }
}
