//
//  TodayCalendarViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/09/2026.
//

import SwiftUI
import Model
import VanorUI
import AsyncAlgorithms

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
    private var fetchTask: Task<Void, Never>?
    @ObservationIgnored
    var store: Store? {
        didSet {
            if let store, oldValue == nil {
                observeChangesInStore(store: store)
            }
            
        }
    }
    var path: [Path] = [.day(.now)]
    var calendarMonths: [CalendarMonth] = []
    var tags: [TagModel] = []
    var selectedTags: Set<TagModel> = .init()
    var currentMonth: CalendarMonth? = nil
    var fullScreenPresentation: FullScreenPresentation? = nil
    
    init() {
        runPreliminaryFetch()
    }
    
    func runPreliminaryFetch() {
        fetchTask?.cancel()
        fetchTask = Task {
            await fetchData()
        }
    }
    
    func fetchData() async {
        await withDiscardingTaskGroup { group in
            group.addTask {
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
                    print("(DEBUG) calendarMonths.days: ", calendarMonths.flatMap(\.days).count)
                    self?.currentMonth = calendarMonths.first(where: { $0.month == Date.now.month })
                }
            }
            
            group.addTask {
                let tags = await CueTag.fetchAllTags(inBackground: false).map { TagModel.from($0) }
                await MainActor.run {
                    self.tags = tags
                }
            }
        }
    }
    
    private func observeChangesInStore(store: Store) {
        
        let tagsObservation = Observations({ store.tags }).map({ _ in () }).dropFirst(1)
        let reminderLogObsersvation = store.hasLoggedReminder.dropFirst(1)
        let reminder = Observations({ store.reminders }).map({ _ in () }).dropFirst(1)
        
        Task {
            for await _ in merge(tagsObservation, reminderLogObsersvation, reminder) {
                await self.fetchData()
            }
        }
    }
}
