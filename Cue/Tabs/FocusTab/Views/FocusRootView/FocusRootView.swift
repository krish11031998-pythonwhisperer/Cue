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
        .task {
            if viewModel.store == nil {
                viewModel.store = store
            }
            viewModel.fetchSessionsAndRoutines()
        }
    }
}


@Observable
@MainActor
class FocusRootViewModel {
    
    enum Presentation: Identifiable {
        case presentCreateFocusSession
        
        var id: String {
            switch self {
            case .presentCreateFocusSession:
                return "presentCreateFocusSession"
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
    
    var calendarDay: CalendarDay? = nil
    var presentation: Presentation? = nil
    var fullScreenPresentation: FullScreenPresentation? = nil
    var sections: [DiffableCollectionSection] = []
    var cancellables: Set<AnyCancellable> = .init()
    @ObservationIgnored
    var store: Store?
    
    init() {
        observeNotification()
    }
    
    func fetchSessionsAndRoutines() {
        Task { @MainActor [weak self] in
            await withDiscardingTaskGroup { [weak self] group in
                group.addTask {
                    await self?.fetchRemindersForToday()
                }
                
                group.addTask {
                    await self?.fetchFocusSession()
                }
            }
        }
    }
    
    // MARK: - Fetch Focus Session
    
    func fetchFocusSession() {
        #if DEBUG
        let focusSession: [FocusSessionModel] = FocusSessionModel.allExamples
        #else
        let focusSession = store?.fetchAllFocusSessions().map(FocusSessionModel.init(from:)) ?? []
        #endif
        let focusedRoutineSection = setupFocusedSessionSection(focusSession)
        let customFocusSection = setupCustomFocusSessionSection(focusSession)
        
        self.sections = [focusedRoutineSection, customFocusSection].compactMap { $0 }
    }
    
    
    // MARK: - Fetch Routines
    
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
    
    
    // MARK: - Focused Routines
    
    private func setupFocusedSessionSection(_ focusSessions: [FocusSessionModel]) -> DiffableCollectionSection? {
        let focusSessionsWithRoutines = focusSessions.filter { $0.reminder != nil }
        guard !focusSessionsWithRoutines.isEmpty else { return nil }
        
        let action: (FocusSessionModel) -> Callback = { [weak self] focusSessionModel in
            { [weak self] in
                // do something here
                self?.fullScreenPresentation = .startFocusSession(focusSessionModel)
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
                self?.fullScreenPresentation = .startFocusSession(focusSessionModel)
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
            let cardModel: CustomFocusSessionCard.Model = .init(sessionType: sessionType, name: $0.name, timerDuration: $0.timerDuration, action: action($0))
            return DiffableCollectionItem<CustomFocusSessionCard>(cardModel)
        }
        
        let layout: NSCollectionLayoutSection = {
            let group = NSCollectionLayoutGroup.custom(layoutSize: .init(widthDimension: .fractionalWidth(0.92), heightDimension: .fractionalWidth(1.08))) { env in
                let spacing: CGFloat = 8
                let containerWidth = (env.container.effectiveContentSize.width - spacing).half
                let contentHeight = (env.container.effectiveContentSize.height - spacing).half
                let size = CGSize(width: containerWidth, height: contentHeight)
                
                var maxY: CGFloat = .zero
                var maxX: CGFloat = .zero
                var frames: [NSCollectionLayoutGroupCustomItem] = []
                
                for i in 0..<4 {
                    frames.append(.init(frame: .init(origin: .init(x: maxX, y: maxY), size: size)))
                    if i%2 == 0 {
                        maxX += containerWidth + spacing
                    } else {
                        maxX = 0
                        maxY += contentHeight + spacing
                    }
                }
                
                return frames
            }
            
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 8
            section.contentInsets = .init(vertical: 10, horizontal: 16)
            section.orthogonalScrollingBehavior = .groupPaging

            return section
        }().addHeader()

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
