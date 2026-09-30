//
//  ManageTabViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 26/09/2026.
//

import Foundation
import CoreData
import SwiftUI
import VanorUI
import Model
import AsyncAlgorithms

@MainActor
@Observable
class ManageViewModel {
    
    typealias RoutineCardConfig = RoutineTimelineCard.Config
    fileprivate typealias RoutineCardDayConfig = RoutineTimelineCard.RoutineDay
    
    fileprivate enum Sections: Int {
        case routineGrid = 0
    }
    
    enum Navigation: Hashable {
        case routineDetail(ReminderModel, RoutineCardConfig)
    }
    
    var sections: [DiffableCollectionSection] = []
    var tagChipModel: [TagChipView.Model] = []
    var tagChipFrame: CGRect = .init()
    var namespaceID: Namespace.ID = Namespace.init().wrappedValue
    var path: [Navigation] = []
    @ObservationIgnored
    private var routinesWithConfig: [(ReminderModel, RoutineCardConfig)] = []
    @ObservationIgnored
    private var scheduledRoutines: [ReminderModel] = [] {
        didSet {
            self.setupTagChipViewModel()
        }
    }
    @ObservationIgnored
    var selectedTags: Set<NSManagedObjectID> = .init() {
        didSet {
            self.setupTagChipViewModel()
            self.filterBasedOnTags()
        }
    }
    @ObservationIgnored
    var tags: [TagModel] = [] {
        didSet {
            self.setupTagChipViewModel()
        }
    }
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
        let action: (ReminderModel, RoutineCardConfig) -> Callback = { [weak self] (reminder, config) in
            // Do something
            return {
                self?.path.append(.routineDetail(reminder, config))
            }
        }
        
        let cells: [DiffableCollectionCellProvider] = routineTimelineCards.sorted(by: { $0.0.title < $1.0.title }).map { (reminderModel, routineCardConfig) in
            return DiffableCollectionItem<RoutineTimelineCard>(.init(config: routineCardConfig, namespaceID: namespaceID, action: action(reminderModel, routineCardConfig)))
        }
        
        let layout = NSCollectionLayoutSection.gridLayout(itemSize: .init(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(54)), groupSpacing: .fixed(16), interGroupSpacing: 16)
        
        self.sections = [.init(Sections.routineGrid.rawValue,
                               cells: cells,
                               header: nil,
                               footer: nil,
                               decorationItem: nil,
                               sectionLayout: layout)]
    }
    
    private func filterBasedOnTags() {
        guard !selectedTags.isEmpty else {
            self.setupSections(routinesWithConfig)
            return
        }
        
        let filteredRoutines = routinesWithConfig.filter { (routine, __) in
            routine.tags.contains { selectedTags.contains($0.objectId) }
        }
        
        self.setupSections(filteredRoutines)
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
        scheduledRoutines = recurringRoutines
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
                            if day.loggedReminders.contains(where: { $0.reminder.objectId == routine.objectId }) {
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
                    let attributedTitle = AttributedString(routine.title, attributes: .init([.font: Font.headline, .foregroundColor: LCHColor(color: routine.color).foregroundSecondary]))
                    let icon = Icon(routine.icon)!
                    routineCardModels.append((routine, .init(icon: icon, title: attributedTitle, days: routineDays, color: routine.color)))
                }
                
                return routineCardModels
            }
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run { [weak self] in
                self?.routinesWithConfig = routineTimelineCardModels
                self?.filterBasedOnTags()
            }
        }
    }
    
    // MARK: - Tag Chip View Model
    
    /// Only tags attached to at least one existing, scheduled routine are shown,
    /// and each chip's count reflects the number of those scheduled routines.
    private func setupTagChipViewModel() {
        var scheduledRoutineCountByTag: [NSManagedObjectID: Int] = [:]
        scheduledRoutines.forEach { routine in
            Set(routine.tags.map(\.objectId)).forEach { scheduledRoutineCountByTag[$0, default: 0] += 1 }
        }
        
        let visibleTags = tags.filter { (scheduledRoutineCountByTag[$0.objectId] ?? 0) > 0 }
        
        // Drop selections for tags that are no longer shown, otherwise the grid
        // could stay filtered by a chip the user can no longer deselect.
        let visibleSelectedTags = selectedTags.intersection(visibleTags.map(\.objectId))
        guard visibleSelectedTags == selectedTags else {
            self.selectedTags = visibleSelectedTags
            return
        }
        
        let tagChipModels: [TagChipView.Model] = visibleTags.map { tag in
            let tagID = tag.objectId
            let buttonConfig = TagChipView.ButtonConfig(isSelected: selectedTags.contains(tagID), routineCount: scheduledRoutineCountByTag[tagID] ?? 0) { [weak self] in
                guard let self else { return }
                if self.selectedTags.contains(tagID) {
                    self.selectedTags.remove(tagID)
                } else {
                    self.selectedTags.insert(tagID)
                }
            }
            return .init(name: tag.name, color: tag.color, viewType: .button(buttonConfig))
        }
        self.tagChipModel = tagChipModels
    }
    
    // MARK: - Observations
    
    private func setAllObservations(store: Store) {
        observationOfAllTasks?.cancel()
        observationOfAllTasks = Task {
           await withDiscardingTaskGroup { [weak self] group in
                let _ = group.addTaskUnlessCancelled {
                    await self?.observeRoutines(store)
                }
               
               let _ = group.addTaskUnlessCancelled {
                   await self?.observeTags(store)
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
    
    private func observeTags(_ store: Store) async {
        let tagsStream = Observations { store.tagModels }
        
        for await tags in tagsStream {
            self.tags = tags
        }
    }
}
