//
//  FocusRootViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 12/09/2026.
//

import VanorUI
import Model
import SwiftUI
import Combine

@Observable
@MainActor
class FocusRootViewModel {
    
    enum Presentation: Identifiable {
        case presentCreateFocusSession
        case editFocusSession(FocusSessionModel)
        
        var id: String {
            switch self {
            case .presentCreateFocusSession:
                return "presentCreateFocusSession"
            case .editFocusSession(let focusSessionModel):
                return "editFocusSession_\(focusSessionModel.id)"
            }
        }
    }
    
    enum FullScreenPresentation: Identifiable {
        case startFocusSession(FocusSessionModel)
        case quickStart
        #if !NEW_QUICK_START
        case ongoingSession
        #endif
        
        var id: String {
            switch self {
            case .startFocusSession(let focusSessionModel):
                return "startFocusSession_\(focusSessionModel.id)"
            #if !NEW_QUICK_START
            case .ongoingSession:
                return "ongoingSession"
            #endif
            case .quickStart:
                return "quickStart"
            }
        }
    }
    
    enum Alert: Identifiable {
        case ongoingSession
        
        var title: String {
            switch self {
            case .ongoingSession:
                return "Start another FocusSession ?"
            }
        }
        
        var description: String {
            switch self {
            case .ongoingSession:
                return "You have an ongoing FocusSession. You need to stop it before starting a new one."
            }
        }
        
        var id: String {
            title + description
        }
    }
    
    enum Section: Int, Identifiable {
        case quickStart = 0
        case focusedRoutiunes
        case focusSession
        
        var id: Int { rawValue }
    }
    
    var presentation: Presentation? = nil
    var fullScreenPresentation: FullScreenPresentation? = nil
    var sections: [DiffableCollectionSection] = []
    var cancellables: Set<AnyCancellable> = .init()
    var alert: Alert? = nil
    @ObservationIgnored
    private(set) var initialSetup: Bool = false
    @ObservationIgnored
    private(set) var reminders: [ReminderModel] = []
    @ObservationIgnored
    private(set) var focusSessions: [FocusSessionModel] = []
    @ObservationIgnored
    private var sessionState: FocusSessionState = .idle
    @ObservationIgnored
    var store: Store? {
        didSet {
            initialFetch()
        }
    }
    @ObservationIgnored
    var subscriptionManager: SubscriptionManager?
    @ObservationIgnored
    var performingInitialFetch: Bool = false
    
    var isProUser: Bool {
        subscriptionManager?.userIsPro ?? false
    }
    
    init() {
        #if !NEW_QUICK_START
        observeNotification()
        #endif
    }
    
    func setup(store: Store, subscriptionManager: SubscriptionManager, coordinator: FocusSessionCoordinator) {
        guard !initialSetup else { return }
        // Assign before `store`, whose `didSet` kicks off the fetch that reads `isProUser`.
        self.subscriptionManager = subscriptionManager
        self.store = store
        self.setupObservation(store: store, subscription: subscriptionManager, coordinator: coordinator)
        self.initialSetup = true
    }
    
    // MARK: - Initial Fetch
    
    private func initialFetch() {
        Task { @MainActor in
            self.performingInitialFetch = true
            async let fetchReminders = fetchRemindersForToday()
            async let fetchFocusSessions = fetchFocusSession()
            
            let (reminders, focusSessions) = await (fetchReminders, fetchFocusSessions)
            
            self.reminders = reminders
            self.focusSessions = focusSessions
            self.setupSections(reminders: reminders, focusSessions: focusSessions)
            self.performingInitialFetch = false
        }
    }
    
    func fetchFocusSession() -> [FocusSessionModel] {
        guard let store else { return  [] }
        return store.fetchAllFocusSessions().map { FocusSessionModel(from: $0) }
    }
    
    @concurrent
    func fetchRemindersForToday() async -> [ReminderModel] {
        do {
            let calendarDay = try await CalendarManager.shared.setupCalendarDay(for: .now)
            return calendarDay.reminders
        } catch {
            print("(ERROR) error: ", error.localizedDescription)
        }
        return []
    }
    
    
    // MARK: - Setup Collection Sections
    
    private func setupSections(reminders: [ReminderModel], focusSessions: [FocusSessionModel]) {
        let quickStartSection = quickStart(reminders: reminders)
        let focusedRoutineSection = setupFocusedSessionSection(focusSessions)
        let customFocusSection = setupCustomFocusSessionSection(focusSessions)

        self.sections = [quickStartSection, focusedRoutineSection, customFocusSection].compactMap { $0 }
    }
    
    
    // MARK: - QuickStart
    
    private func quickStart(reminders: [ReminderModel]) -> DiffableCollectionSection {
        let presentQuickStart: Callback = { [weak self] in
            self?.fullScreenPresentation = .quickStart
        }
        
        let startFocusSession: (FocusSessionModel) -> Void = { [weak self] session in
            // do something here
            let ongoingSession = self?.sessionState ?? .idle
            if ongoingSession == .idle {
                self?.fullScreenPresentation = .startFocusSession(session)
            } else {
                self?.alert = .ongoingSession
            }
        }
        
        let model = FocusQuickStartView.Model(reminders: reminders, startTimer: startFocusSession, presentQuickStartView: presentQuickStart)
        let cells: [DiffableCollectionItem] = [DiffableCollectionItem<FocusQuickStartView>(model)]
        
        let layout = NSCollectionLayoutSection.singleColumnLayout(width: .fractionalWidth(1), height: .fractionalWidth(1/0.8), insets: .section(.init(top: 16, leading: 16, bottom: 32, trailing: 16)))
        
        
        let section = DiffableCollectionSection(Section.quickStart.id, cells: cells, sectionLayout: layout)
        
        return section
    }
    
    private func refetchAndUpdateQuickStartSection() async {
        let reminders = await fetchRemindersForToday()
        self.reminders = reminders
        self.updateQuickStartSection(reminders)
    }
    
    private func updateQuickStartSection(_ reminders: [ReminderModel]) {
        let quickStartSection = quickStart(reminders: reminders)
        
        if let idx = self.sections.firstIndex(where: { $0.id == Section.quickStart.id }) {
            self.sections[idx] = quickStartSection
        } else {
            self.sections.insert(quickStartSection, at: 0)
        }
    }
    
    // MARK: - Focused Routines
    
    private func updateFocusSessionSections(_ focusSessions: [FocusSessionModel]) {
        self.focusSessions = focusSessions
        var newSections = sections.filter { $0.id == Section.quickStart.id }
        
        let newFocusSessionSections = [setupFocusedSessionSection(focusSessions), setupCustomFocusSessionSection(focusSessions)].compactMap { $0 }
        
        newSections += newFocusSessionSections
        
        self.sections = newSections
    }
    
    private func setupFocusedSessionSection(_ focusSessions: [FocusSessionModel]) -> DiffableCollectionSection? {
        guard isProUser else { return nil }
        let focusSessionsWithRoutines = focusSessions.filter { $0.reminder != nil }
        guard !focusSessionsWithRoutines.isEmpty else { return nil }
        
        let action: (FocusSessionModel) -> Callback = { [weak self] focusSessionModel in
            { [weak self] in
                // do something here
                let ongoingSession = self?.sessionState ?? .idle
                if ongoingSession == .idle {
                    self?.fullScreenPresentation = .startFocusSession(focusSessionModel)
                } else {
                    self?.alert = .ongoingSession
                }
            }
        }
        
        let cells = focusSessionsWithRoutines.compactMap { focusModel -> DiffableCollectionCellProvider? in
            let sessionType: FocusSessionType
            switch focusModel.sessionType {
            case .classic:
                sessionType = .classic
            case .pomodoro:
                sessionType = .pomodoro(currentIndex: 0, total: 0)
            @unknown default:
                sessionType = .classic
            }
            
            guard let reminder = focusModel.reminder else { return nil }
            
            let model: RoutineFocusSessionCard.Model = .init(sessionType: sessionType,
                                                             name: reminder.title,
                                                             alarmIsOn: focusModel.alarm != .off,
                                                             appShieldIsOn: focusModel.blockedApps != nil,
                                                             tasks: reminder.tasks.count,
                                                             timerDuration: focusModel.timerDuration,
                                                             theme: .init(color: reminder.color),
                                                             icon: .init(reminder.icon)!,
                                                             action: action(focusModel))
            
            return DiffableCollectionItem<RoutineFocusSessionCard>(model)
        }
        let layout = NSCollectionLayoutSection.singleRowLayout(width: .absolute(175), height: .absolute(225),
                                                               insets: .section(.init(top: 16, leading: 16, bottom: 32, trailing: 16)),
                                                               spacing: 8).addHeader()
        layout.orthogonalScrollingBehavior = .groupPaging

        let header = CollectionSupplementaryView<FocusSectionHeaderView>(.init(title: "Focused Routines"))

        let section = DiffableCollectionSection(Section.focusedRoutiunes.id, cells: cells, header: header, sectionLayout: layout)

        return section
    }
    
    
    // MARK: - Created Focus Sessions
    
    private func setupCustomFocusSessionSection(_ focusSession: [FocusSessionModel]) -> DiffableCollectionSection? {
        let customFocusSessions = focusSession.filter { $0.reminder == nil }
        
        let action: (FocusSessionModel) -> Callback = { [weak self] focusSessionModel in
            { [weak self] in
                // do something here
                
                let ongoingSession = self?.sessionState ?? .idle
                if ongoingSession == .idle {
                    self?.fullScreenPresentation = .startFocusSession(focusSessionModel)
                } else {
                    self?.alert = .ongoingSession
                }
            }
        }
        
        let deleteAction: (FocusSessionModel) -> Callback = { [weak self] focusSession in
            { [weak self] in
                self?.store?.deleteFocusSession(focusSessionID: focusSession.objectId)
            }
        }

        let editAction: (FocusSessionModel) -> Callback = { [weak self] focusSession in
            { [weak self] in
                self?.presentation = .editFocusSession(focusSession)
            }
        }
        
        var cells: [DiffableCollectionCellProvider] = allowedFocusSessions(customFocusSessions).map {
            let sessionType: FocusSessionType
            switch $0.sessionType {
            case .classic:
                sessionType = .classic
            case .pomodoro:
                sessionType = .pomodoro(currentIndex: 0, total: 0)
            @unknown default:
                sessionType = .classic
            }
            
            let imageModel: CustomFocusSessionCard.ImageModel = .init(url: $0.imageFileName.map { ImageFileManager.url(for: $0) }) { url in
                try? ImageFileManager.retrieveImage(for: url)
            }
            
            let cardModel: CustomFocusSessionCard.Model = .init(sessionType: sessionType,
                                                                image: imageModel,
                                                                name: $0.name,
                                                                timerDuration: $0.timerDuration,
                                                                deleteAction: deleteAction($0),
                                                                editAction: editAction($0),
                                                                action: action($0))
            return DiffableCollectionItem<CustomFocusSessionCard>(cardModel)
        }
        
        let layout: NSCollectionLayoutSection = .orthogonalGrid(gridWidth: .fractionalWidth(0.92),
                                                                gridHeight: .fractionalWidth(1.08),
                                                                spacing: 8,
                                                                contentInsets: .init(top: 16, leading: 16, bottom: 16, trailing: 16)).addHeader()
        
        let addNewSession = DiffableCollectionItem<AddCustomFocusSessionCard>(.init { [weak self] in
            self?.createFocusSessionAction()
        })
        
        cells.append(addNewSession)

        let header = CollectionSupplementaryView<FocusSectionHeaderView>(.init(title: "Focus Sessions"))

        let section = DiffableCollectionSection(Section.focusSession.id, cells: cells, header: header, sectionLayout: layout)

        return section
    }
    
    
    // MARK: - Observations
    
    #if !NEW_QUICK_START
    private func observeNotification() {
        let quickStart: AnyPublisher<FullScreenPresentation, Never> = NotificationCenter.default.publisher(for: .presentQuickStart)
            .map { _ in FullScreenPresentation.quickStart }
            .eraseToAnyPublisher()
        
        let ongoingSession: AnyPublisher<FullScreenPresentation, Never> = NotificationCenter.default.publisher(for: .currentFTSession)
            .map { _ in FullScreenPresentation.ongoingSession }
            .eraseToAnyPublisher()
        
        Publishers.Merge(quickStart, ongoingSession)
            .receive(on: DispatchQueue.main)
            .sinkReceive { [weak self] in
                self?.fullScreenPresentation = $0
            }
            .store(in: &cancellables)
    }
    #endif
    
    
    // MARK: - Observations
    
    func setupObservation(store: Store, subscription: SubscriptionManager, coordinator: FocusSessionCoordinator) {
        Task {
            await withDiscardingTaskGroup { group in
                group.addTask {
                    await self.observeReminder(store: store)
                    print("(DEBUG) Done Observing Reminder for Today")
                }
                
                group.addTask {
                    await self.observeFocusSessions(store: store)
                    print("(DEBUG) Done Observing Focus Sessions")
                }
                
                group.addTask {
                    await self.observeOngoingSession(focusCoordinator: coordinator)
                    print("(DEBUG) Done Observing Ongoing Sessions")
                }
                
                group.addTask {
                    await self.observeProUserStatus(subscription: subscription)
                }
            }
            
        }
    }
    
    private func observeReminder(store: Store) async {
        let reminderStream = Observations { store.reminderModels }
        for await reminders in reminderStream.dropFirst(1) {
            print("(DEBUG) Updating Reminders....")
            let remindersScheduledForToday = reminders.filter(\.occursToday)
            self.reminders = remindersScheduledForToday
            updateQuickStartSection(remindersScheduledForToday)
        }
    }
    
    private func observeFocusSessions(store: Store) async {
        let focusSessionStream = Observations { store.focusSessionModels }
        for await focusSession in focusSessionStream.dropFirst(1) {
            print("(DEBUG) \(Self.self).\(#function) count: ", focusSession.count)
            self.updateFocusSessionSections(focusSession)
        }
    }
    
    private func observeOngoingSession(focusCoordinator: FocusSessionCoordinator) async {
        let ongoingSession = Observations { focusCoordinator.state }
        for await state in ongoingSession {
            sessionState = state
        }
    }
    
    private func observeProUserStatus(subscription: SubscriptionManager) async {
        let proUserStatus = Observations({ subscription.userIsPro })
        for await _ in proUserStatus.dropFirst(1) {
            self.initialFetch()
        }
    }
    
    
    // MARK: - Pro Feature Action

    func createFocusSessionAction() {
        guard let subscriptionManager else { return }
        subscriptionManager.focusSessionCreationAction(existingSessions: focusSessions.count) { [weak self] in
            self?.presentation = .presentCreateFocusSession
        }
    }
    
    private func allowedFocusSessions(_ focusSessions: [FocusSessionModel]) -> [FocusSessionModel] {
        guard let subscriptionManager else { return [] }
        return subscriptionManager.allowedFocusSessions(focusSessions)
    }
}
