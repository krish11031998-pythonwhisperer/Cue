//
//  CalendarViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 03/02/2026.
//

import Foundation
import Model

@Observable
class CalendarViewModel {
    
    struct Section: Identifiable {
        let month: Int
        let days: [CalendarDay]
        
        var id: Int {
            month
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
}
