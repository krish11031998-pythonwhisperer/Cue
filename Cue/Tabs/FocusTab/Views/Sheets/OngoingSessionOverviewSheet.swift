//
//  OngoingSessionOverviewSheet.swift
//  Cue
//
//  Created by Krishna Venkatramani on 19/08/2026.
//

import VanorUI
import SwiftUI
import Model
import FamilyControls

@Observable
@MainActor
class OngoingSessionOverviewSheetModel {
    
    var selectedDetent: PresentationDetent = .medium
    var completedTasks: Set<ReminderTaskModel> = .init()
    var isSaving: Bool = false
    var headerSize: CGSize = .zero
    var phaseFactor: CGFloat = 0
    @ObservationIgnored
    var canStartTracking: Bool = false
    @ObservationIgnored
    var totalChange: CGFloat = 0
    @ObservationIgnored
    var saveTask: ((ReminderTaskModel) -> Void)?
    
    func saveTasks() async {
        let completedTasks = self.completedTasks
        isSaving = true
        await withDiscardingTaskGroup { [weak self] group in
            for completedTask in completedTasks {
                group.addTask { @MainActor in
                    self?.saveTask?(completedTask)
                }
            }
        }
        isSaving = false
    }
    
    func updateCompletedTask(_ sessionTask: ReminderTaskModel) {
        if completedTasks.contains(sessionTask) {
            completedTasks.remove(sessionTask)
        } else {
            completedTasks.insert(sessionTask)
        }
    }
    
    func sessionRowModel(_ sessionTask: ReminderTaskModel) -> ReminderTaskView.Model {
        let callback: Callback = { [weak self] in
            self?.updateCompletedTask(sessionTask)
        }
        
        return .init(taskTitle: sessionTask.title,
                     icon: .init(sessionTask.icon)!,
                     viewType: .checklist(completedTasks.contains(sessionTask), callback),
                     action: callback)
    }
}

struct OngoingSessionOverviewSheet: View {

    let factor: CGFloat = .totalHeight * 0.35
    @Environment(FocusSessionCoordinator.self) var coordinator
    @Environment(Store.self) var store
    @Environment(\.dismiss) var dismiss
    @Environment(\.theme) var theme
    
    let sessionTasks: [ReminderTaskModel]
    let selectedPresentationDetent: PresentationDetent
    @State private var viewModel: OngoingSessionOverviewSheetModel = .init()
    
    init(sessionTasks: [ReminderTaskModel], selectedPresentationDetent: PresentationDetent) {
        self.sessionTasks = sessionTasks
        self.selectedPresentationDetent = selectedPresentationDetent
    }
    
    var name: String? {
        coordinator.sessionAttributes?.name
    }
    
    var sessionType: FocusSessionType {
        switch coordinator.selectedTimerType {
        case .classic:
            return .classic
        case .pomodoro:
            return .pomodoro(currentIndex: coordinator.currentSessionIndex, total: coordinator.pomodoroSessionCount)
        }
    }
    
    var icon: Icon? {
        coordinator.sessionAttributes?.icon
    }
    
    var timeIntervalRange: ClosedRange<Date> {
        guard let session = coordinator.session else {
            fatalError("Can't have `nil` as session")
        }
        
        switch coordinator.selectedTimerType {
        case .classic:
            guard let startDate = session.startTime, let endDate = session.endTime else {
                fatalError("Session's can't have nil startTime and endTime")
            }
            return startDate...endDate
        case .pomodoro:
            guard let pomodoroSession = session as? PomodoroFocusSession,
                  let startDate = pomodoroSession.currentSession.startTime,
                  let endDate = pomodoroSession.currentSession.endTime
            else {
                fatalError("Session's can't have nil startTime and endTime")
            }
            
            return startDate...endDate
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color.cueItBackground
                    .ignoresSafeArea(edges: .vertical)
                    .opacity(viewModel.phaseFactor)
                
                SessionOverviewHeaderView(name: name,
                                          sessionType: sessionType,
                                          icon: icon,
                                          timeIntervalRange: timeIntervalRange,
                                          timeProgress: coordinator.progress)
                    .popIn(percent: 1 - viewModel.phaseFactor)
                    .onGeometryChange(for: CGSize.self, of: { $0.size }) { newValue in
                        viewModel.headerSize = newValue
                    }
                    .padding(.horizontal, 24)
                    .opacity(viewModel.phaseFactor)
                
                ScrollView {
                    if !sessionTasks.isEmpty {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            Section {
                                VStack(spacing: 4) {
                                    ForEach(sessionTasks) { sessionTask in
                                        ReminderTaskView(model: viewModel.sessionRowModel(sessionTask))
                                            .transaction { txn in
                                                txn.disablesAnimations = true
                                            }
                                    }
                                    .modifier(RowBackground())
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                            } header: {
                                Text("Subtasks")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(theme.foregroundSecondary)
                                    .padding(.top, (viewModel.headerSize.height + 16) * viewModel.phaseFactor)
                                    .padding(.bottom, 16)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    } else {
                        ContentUnavailableView("No tasks to track in this session", systemSymbol: .checkmarkCircle, description: nil)
                            .padding(.top, (viewModel.headerSize.height + 16) * viewModel.phaseFactor)
                            .frame(maxHeight: .infinity, alignment: .center)
                    }
                }
                .scrollEdgeEffectStyle(.soft, for: .vertical)
                .onScrollGeometryChange(for: CGSize.self) {
                    return $0.containerSize
                } action: { oldValue, newValue in
                    guard viewModel.canStartTracking else { return }
                    let diff = abs(oldValue.height - newValue.height) + viewModel.totalChange
                    viewModel.totalChange = min(diff, factor)
                    let calculatedFactor = min(1, viewModel.totalChange / factor)
                    if oldValue.height < newValue.height {
                        viewModel.phaseFactor = calculatedFactor
                    } else if oldValue.height > newValue.height {
                        viewModel.phaseFactor = 1 - calculatedFactor
                    }
                }
                .onScrollPhaseChange { oldPhase, newPhase in
                    switch newPhase {
                    case .idle:
                        print("(DEBUG) Phase: \(newPhase) - \(selectedPresentationDetent)")
                        viewModel.canStartTracking = false
                        viewModel.totalChange = 0
                    case .interacting:
                        print("(DEBUG) Phase: \(newPhase) - \(selectedPresentationDetent)")
                        viewModel.canStartTracking = true
                    case .tracking, .decelerating, .animating:
                        break
                    }
                }
            }
            .navigationTitle("Session Overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .close) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save", systemSymbol: .squareAndArrowDown) {
                        Task { @MainActor in
                            await viewModel.saveTasks()
                            dismiss()
                        }
                    }
                    .disabled(viewModel.isSaving)
                    .tint(theme.baseColor)
                    .buttonStyle(.glassProminent)
                }
            }
            .safeAreaInset(edge: .bottom, alignment: .center, spacing: 8) {
                VStack(alignment: .leading, spacing: 14) {
                    SessionOverviewBottomEdgeView(name: name, viewType: .sheetOverview(timeIntervalRange), sessionType: sessionType, icon: icon)
                    HStack(alignment: .center, spacing: 4) {
                        if let startDate = coordinator.session?.startTime, let duration = coordinator.session?.timerDuration {
                            SessionOverviewBottomEdgeAccesoryView(viewInfo: .alarm(startDate.addingTimeInterval(duration)))
                        }
                        
                        SessionOverviewBottomEdgeAccesoryView(viewInfo: .appSheild(coordinator.shieldActivities))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 24)
            }
        }
    }
}
