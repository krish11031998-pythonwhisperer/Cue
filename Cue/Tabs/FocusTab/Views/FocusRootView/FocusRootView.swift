//
//  FocusRootView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 29/08/2026.
//

import VanorUI
import Model
import SwiftUI
import Combine


struct FocusRootView: View {
    
    @Bindable var coordinator: FocusSessionCoordinator
    @Environment(Store.self) var store
    @State private var viewModel: FocusRootViewModel = .init()
    
    init(coordinator: FocusSessionCoordinator) {
        self.coordinator = coordinator
    }
    
    var navBarTitle: AttributedString {
        .init("Focus Session", attributes: .init([.font: Font.bitcountRegular(style: .largeTitle)]))
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .center) {
                Color.cueItBackground
                    .ignoresSafeArea(edges: .all)
                if viewModel.sections.isEmpty {
                    ContentUnavailableView("No Focus Sessions", systemImage: "timer", description: Text("Create a focus session to get started."))
                } else {
                    CollectionView(section: viewModel.sections, completion: nil)
                        .ignoresSafeArea(edges: .vertical)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemSymbol: .plus) {
                        self.viewModel.presentation = .presentCreateFocusSession
                    }
                }
            }
            .navigationTitle(Text(navBarTitle))
            .navigationBarTitleDisplayMode(.automatic)
        }
        .sheet(item: $viewModel.presentation, content: { presentation in
            switch presentation {
            case .presentCreateFocusSession:
                CreateFocusSessionSheet(mode: .create)
            case .editFocusSession(let focusSessionModel):
                CreateFocusSessionSheet(mode: .edit(focusSessionModel))
            }
        })
        .fullScreenCover(item: $viewModel.fullScreenPresentation, content: { fullScreenPresentation in
            switch fullScreenPresentation {
            case .startFocusSession(let focusSessionModel):
                FTActiveSessionView(coordinator: coordinator, mode: .startSession(focusSessionModel))
            case .ongoingSession:
                FTActiveSessionView(coordinator: coordinator, mode: .ongoing)
            case .quickStart:
                FTQuickStartView(coordinator: coordinator, reminders: viewModel.calendarDay?.reminders ?? [])
            }
        })
        .alert(item: $viewModel.alert, content: { alert in
            Alert(title: Text(alert.title).font(.headline),
                  message: Text(alert.description).font(.subheadline), primaryButton: .default(Text("OK")), secondaryButton: .cancel())
        })
        .task {
            if viewModel.store == nil {
                viewModel.store = store
            }
            await viewModel.setup(store: store, coordinator: coordinator)
        }
    }
}


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
        case ongoingSession
        
        var id: String {
            switch self {
            case .startFocusSession(let focusSessionModel):
                return "startFocusSession_\(focusSessionModel.id)"
            case .ongoingSession:
                return "ongoingSession"
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
    
    var calendarDay: CalendarDay? = nil
    var presentation: Presentation? = nil
    var fullScreenPresentation: FullScreenPresentation? = nil
    var sections: [DiffableCollectionSection] = []
    var cancellables: Set<AnyCancellable> = .init()
    var alert: Alert? = nil
    @ObservationIgnored
    private var sessionState: FocusSessionState = .idle
    @ObservationIgnored
    var store: Store?
    
    init() {
        observeNotification()
    }
    
    // MARK: - Fetch Focus Session
    
    func fetchFocusSession() {
        let focusSessions = (store?.fetchAllFocusSessions() ?? []).map { FocusSessionModel(from: $0) }
        setupSections(focusSessions)
    }
    
    
    // MARK: - Fetch Routines
    
    func setup(store: Store, coordinator: FocusSessionCoordinator) async {
        await withDiscardingTaskGroup { group in
            group.addTask {
                await self.fetchRemindersForToday()
                print("(DEBUG) Done Fetching Reminder for Today")
            }
            
            group.addTask {
                await self.observeFocusSessions(store: store)
                print("(DEBUG) Done Observing Focus Sessions")
            }
            
            group.addTask {
                await self.observeOngoingSession(focusCoordinator: coordinator)
                print("(DEBUG) Done Observing Ongoing Sessions")
            }
        }
    }
    
    @concurrent
    func fetchRemindersForToday() async {
        do {
            let calendarDay = try await CalendarManager.shared.setupCalendarDay(for: .now)
            await MainActor.run {
                self.calendarDay = calendarDay
            }
        } catch {
            print("(ERROR) error: ", error.localizedDescription)
        }
    }
    
    
    // MARK: - Setup Collection Sections
    
    private func setupSections(_ focusSessions: [FocusSessionModel]) {
        print("(DEBUG) \(Self.self).\(#function) count: ", focusSessions.count)
        let models: [FocusSessionModel]
        #if DEBUG
        let savedFocusSession = focusSessions
        if savedFocusSession.isEmpty {
            models = FocusSessionModel.allExamples
        } else {
            models = savedFocusSession + FocusSessionModel.allExamples.filter { $0.reminder != nil }
        }
        #else
        models = focusSessions.map { FocusSessionModel(from: $0) }
        #endif
        let focusedRoutineSection = setupFocusedSessionSection(models)
        let customFocusSection = setupCustomFocusSessionSection(models)
        
        self.sections = [focusedRoutineSection, customFocusSection].compactMap { $0 }
    }
    
    // MARK: - Focused Routines
    
    private func setupFocusedSessionSection(_ focusSessions: [FocusSessionModel]) -> DiffableCollectionSection? {
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
                                                               insets: .section(.init(vertical: 10, horizontal: 16)),
                                                               spacing: 8).addHeader()
        layout.orthogonalScrollingBehavior = .groupPaging

        let header = CollectionSupplementaryView<FocusSectionHeaderView>(.init(title: "Focused Routines"))

        let section = DiffableCollectionSection(10, cells: cells, header: header, sectionLayout: layout)

        return section
    }
    
    
    // MARK: - Created Focus Sessions
    
    private func setupCustomFocusSessionSection(_ focusSession: [FocusSessionModel]) -> DiffableCollectionSection? {
        let customFocusSessions = focusSession.filter { $0.reminder == nil }
        guard !customFocusSessions.isEmpty else { return nil }
        
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
        
        let cells = customFocusSessions.map {
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
                                                                contentInsets: .init(vertical: 10, horizontal: 16)).addHeader()

        let header = CollectionSupplementaryView<FocusSectionHeaderView>(.init(title: "Focus Sessions"))

        let section = DiffableCollectionSection(1, cells: cells, header: header, sectionLayout: layout)

        return section
    }
    
    
    // MARK: - Observations
    
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
    
    func observe(store: Store, focusSessionCoordinator: FocusSessionCoordinator) async {
       await withDiscardingTaskGroup(returning: Void.self) { group  in
            group.addTask {
                await self.observeFocusSessions(store: store)
            }
            
            group.addTask {
                await self.observeOngoingSession(focusCoordinator: focusSessionCoordinator)
            }
        }
    }
    
    func observeFocusSessions(store: Store) async {
        let focusSessionStream = Observations { store.focusSessions.map { FocusSessionModel(from: $0) } }
        for await focusSession in focusSessionStream {
            print("(DEBUG) \(Self.self).\(#function) count: ", focusSession.count)
            setupSections(focusSession)
        }
    }
    
    func observeOngoingSession(focusCoordinator: FocusSessionCoordinator) async {
        let ongoingSession = Observations { focusCoordinator.state }
        for await state in ongoingSession {
            sessionState = state
        }
    }
}

#warning("Move this to VanorUI")
final class FocusSectionHeaderView: UICollectionViewCell, ConfigurableCollectionSupplementaryView {

    struct Model: Hashable {
        let title: String
    }

    func configure(with model: Model) {
        self.contentConfiguration = UIHostingConfiguration {
            Text(model.title)
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .margins(.vertical, .zero)
    }
}
