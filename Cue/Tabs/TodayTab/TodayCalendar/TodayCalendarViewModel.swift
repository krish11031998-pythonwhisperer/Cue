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
    var currentMonth: Section? = nil
    var fullScreenPresentation: FullScreenPresentation? = nil
    
    func fetchCalendarSection() {
        calendarDayTask?.cancel()
        calendarDayTask = Task {
            let currentMonth = Calendar.current.dateComponents([.month], from: .now).month!
            //            let months = Array(1...monthCount)
            
            //            let sections: [Section] = await withTaskGroup(of: Section.self) { group in
            //                for i in months {
            //                    group.addTask {
            //                        let calendarDays = await CalendarManager.shared.setupCalendayDaysInCurrentYear(month: i)
            //                        return Section(month: i, days: calendarDays)
            //                    }
            //                }
            //
            //                var sections: [Section] = []
            //                for await section in group {
            //                    sections.append(section)
            //                }
            //
            //                return sections.sorted(by: { $0.month < $1.month })
            //            }
            
            let calendarDays = await CalendarManager.shared.setupCalendayDaysInCurrentYear(month: currentMonth)
            let section = Section(month: currentMonth, days: calendarDays)
            
            await MainActor.run { [weak self] in
                //                self?.calendarData = sections
                self?.currentMonth = section
            }
        }
    }
}
