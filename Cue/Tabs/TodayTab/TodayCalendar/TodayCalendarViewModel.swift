//
//  TodayCalendarViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/09/2026.
//

import SwiftUI
import Model
import VanorUI

@Observable
@MainActor
class TodayCalendarViewModel {
        
    enum Path: Identifiable, Hashable {
        case day(Date)
        
        var id: String {
            switch self {
            case .day(let date):
                return "today_\(date.day)_\(date.month)"
            }
        }
    }
    
    enum FullScreenPresentation: Identifiable {
        case settings
        
        var id: String {
            switch self {
            case .settings:
                return "Settings"
            }
        }
    }
    
    @ObservationIgnored
    private var calendarDayTask: Task<Void, Never>?
    var path: [Path] = [.day(.now)]
    var calendarMonths: [CalendarMonth] = []
    var currentMonth: CalendarMonth? = nil
    var fullScreenPresentation: FullScreenPresentation? = nil
    
    func fetchCalendarSection() {
        calendarDayTask?.cancel()
        calendarDayTask = Task {
            let monthCount = Calendar.current.monthSymbols.count
            let months = Array(1...monthCount)
            
            let calendarMonths: [CalendarMonth] = await withTaskGroup(of: CalendarMonth.self) { group in
                for i in months {
                    group.addTask {
                        let calendarMonth = await CalendarMonth.fetch(month: i)
                        return calendarMonth
                    }
                }
                
                var sections: [CalendarMonth] = []
                for await section in group {
                    sections.append(section)
                }
                
                return sections.sorted(by: { $0.month < $1.month })
            }
            
            await MainActor.run { [weak self] in
                self?.calendarMonths = calendarMonths
                self?.currentMonth = calendarMonths.first(where: { $0.month == Date.now.month })
            }
        }
    }
}
