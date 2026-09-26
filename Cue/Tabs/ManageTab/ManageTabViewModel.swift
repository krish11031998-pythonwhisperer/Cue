//
//  ManageTabViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 26/09/2026.
//

import Foundation
import SwiftUI
import VanorUI
import Model
import AsyncAlgorithms

@MainActor
@Observable
class ManageViewModel {
    
    fileprivate typealias RoutineCardConfig = RoutineTimelineCard.Config
    fileprivate typealias RoutineCardDayConfig = RoutineTimelineCard.RoutineDay
    
    fileprivate enum Sections: Int {
        case routineGrid = 0
    }
    
    var sections: [DiffableCollectionSection] = []
    @ObservationIgnored
    private var calendarFetchTask: Task<Void, Never>?
    @ObservationIgnored
    private var observationOfAllTasks: Task<Void, Never>?
    @ObservationIgnored
    var store: Store? {
        didSet {
            guard let store, oldValue == nil else { return }
            self.setAllObservations(store: store)
        }
    }
    
    private func setupSections(_ routineTimelineCards: [(ReminderModel, RoutineCardConfig)]) {
        let action: (ReminderModel) -> Callback = { reminder in
            // Do something
            return { }
        }
        
        let cells: [DiffableCollectionCellProvider] = routineTimelineCards.sorted(by: { $0.0.title < $1.0.title }).map { (reminderModel, routineCardConfig) in
            return DiffableCollectionItem<RoutineTimelineCard>(.init(config: routineCardConfig, action: action(reminderModel)))
        }
        
        let layout = NSCollectionLayoutSection.gridLayout(itemSize: .init(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(54)), groupSpacing: .fixed(16), interGroupSpacing: 16)
        
        self.sections = [.init(Sections.routineGrid.rawValue,
                               cells: cells,
                               header: nil,
                               footer: nil,
                               decorationItem: nil,
                               sectionLayout: layout)]
    }
    
    
    // MARK: - Fetch Logs
    
    private func fetchLogs(routines: [ReminderModel]) {
        let recurringRoutines = routines.filter {
            guard let schedule = $0.schedule else { return false }
            
            if (schedule.intervalWeeks ?? 0) > 0 {
                return true
            } else if (schedule.calendarDates?.count ?? 0) > 0 {
                return true
            }
            return false
        }
        calendarFetchTask?.cancel()
        calendarFetchTask = Task(priority: .userInitiated) { [weak self] in
            let calendarDays = await CalendarManager.shared.setupCalendarForExactOneMonthFromToday()
            
            guard !Task.isCancelled else { return }
            
            let routineTimelineCardModels: [(ReminderModel, RoutineCardConfig)] = await withTaskGroup(of: (ReminderModel, [RoutineCardDayConfig]).self) { group in
                var routineCardModels: [(ReminderModel, RoutineCardConfig)] = []
                recurringRoutines.forEach { routine in
                    let _ = group.addTaskUnlessCancelled {
                        var routineDays: [RoutineCardDayConfig] = []
                        calendarDays.forEach { day in
                            guard !Task.isCancelled else { return }
                            if day.loggedReminders.contains(where: { $0.reminder == routine }) {
                                routineDays.append(.init(date: day.date, isLogged: true))
                            } else {
                                routineDays.append(.init(date: day.date, isLogged: false))
                            }
                        }
                        return (routine, routineDays)
                    }
                }
                
                guard !Task.isCancelled else { return [] }
                
                for await (routine, routineDays) in group {
                    let attributedTitle = AttributedString(routine.title, attributes: .init([.font: Font.bitcountRegular(style: .body)]))
                    let icon = Icon(routine.icon)!
                    routineCardModels.append((routine, .init(icon: icon, title: attributedTitle, days: routineDays, color: routine.color)))
                }
                
                return routineCardModels
            }
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run { [weak self] in
                self?.setupSections(routineTimelineCardModels)
            }
        }
    }
    
    // MARK: - Observations
    
    private func setAllObservations(store: Store) {
        observationOfAllTasks?.cancel()
        observationOfAllTasks = Task {
           await withDiscardingTaskGroup { [weak self] group in
                let _ = group.addTaskUnlessCancelled {
                    await self?.observeRoutines(store)
                }
            }
        }
    }
    
    private func observeRoutines(_ store: Store) async {
        let routinesObservations = Observations { store.reminderModels }
        let routineLogStream = store.hasLoggedReminder.map { @MainActor _ in store.reminderModels }
        
        for await routines in merge(routinesObservations, routineLogStream) {
            self.fetchLogs(routines: routines)
        }
    }
}
