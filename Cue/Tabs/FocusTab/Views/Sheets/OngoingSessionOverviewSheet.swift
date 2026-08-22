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
    
    enum Presentation: Int, Identifiable {
        case appSheild = 0
        
        var id: Int {
            rawValue
        }
    }
    
    var selectedDetent: PresentationDetent = .medium
    var presentation: Presentation? = nil
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
    
    let selectedPresentationDetent: PresentationDetent
    @State private var viewModel: OngoingSessionOverviewSheetModel = .init()

    init(selectedPresentationDetent: PresentationDetent) {
        self.selectedPresentationDetent = selectedPresentationDetent
    }

    var sessionTasks: [ReminderTaskModel] {
        coordinator.reminderTasks
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
            dismiss()
            return .init(uncheckedBounds: (Date.now.startOfDay, Date.now.endOfDay))
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
    
    var contentTopMargin: CGFloat {
        viewModel.headerSize.height * viewModel.phaseFactor
    }
    
    var sessionActions: [SessionOverviewHeaderView.AccessoryAction] {
        let alarmAction = SessionOverviewHeaderView.AccessoryAction.alarm(timeIntervalRange.upperBound, coordinator.isAlarmOn) {
            coordinator.toggleAlarm()
        }
        
        let applicationSheild = SessionOverviewHeaderView.AccessoryAction.appSheild(coordinator.shieldActivities, coordinator.appShieldIsOn) {
            if coordinator.appShieldIsOn {
                coordinator.removeAppShield()
            } else {
                viewModel.presentation = .appSheild
            }
        }
        
        return [alarmAction, applicationSheild]
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color.cueItBackground
                    .ignoresSafeArea(edges: .vertical)
                    .opacity(viewModel.phaseFactor)
                
                ScrollView {
                    if !sessionTasks.isEmpty {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            Section {
                                VStack(spacing: 4) {
                                    ForEach(sessionTasks) { sessionTask in
                                        ReminderTaskView(model: viewModel.sessionRowModel(sessionTask))
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .modifier(RowBackground())
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 24))
                            } header: {
                                Text("Subtasks")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(theme.foregroundSecondary)
                                    .padding(.top, contentTopMargin)
                                    .padding(.bottom, 16)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    } else {
                        ContentUnavailableView("No tasks to track in this session", systemSymbol: .checkmarkCircle, description: nil)
                            .padding(.top, contentTopMargin)
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
                        Task { @MainActor in
                            withAnimation(.default) {
                                viewModel.phaseFactor = selectedPresentationDetent == .large ? 1 : 0
                            }
                        }
                    case .interacting:
                        print("(DEBUG) Phase: \(newPhase) - \(selectedPresentationDetent)")
                        viewModel.canStartTracking = true
                    case .tracking, .decelerating, .animating:
                        break
                    }
                }
                
                SessionOverviewHeaderView(name: name,
                                          sessionType: sessionType,
                                          icon: icon,
                                          timeIntervalRange: timeIntervalRange,
                                          timeProgress: coordinator.progress,
                                          actions: sessionActions)
                    .popIn(percent: 1 - viewModel.phaseFactor)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(.cueItBackground.opacity(viewModel.phaseFactor == 1 ? 1 : 0), in: .rect)
                    .onGeometryChange(for: CGSize.self, of: { $0.size }) { newValue in
                        viewModel.headerSize = newValue
                    }
                    .opacity(viewModel.phaseFactor)
            }
            .navigationTitle("Session Overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .close) {
                        Task { @MainActor in
                            coordinator.completedReminderTasks = viewModel.completedTasks
                            dismiss()
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, alignment: .center, spacing: 8) {
                SafeAreaBottomView(name: name ?? "N/A",
                                   timeIntervalRange: timeIntervalRange,
                                   sessionType: sessionType,
                                   icon: icon ?? .unavailableIcon,
                                   shieldActivities: coordinator.shieldActivities,
                                   phaseFactor: viewModel.phaseFactor)
            }
            .sheet(item: $viewModel.presentation, onDismiss: nil) { presentation in
                switch presentation {
                case .appSheild:
                    BlockAppView(selectedActivities: coordinator.shieldActivities) { activities in
                        coordinator.shieldActivities = activities
                        if coordinator.appShieldIsOn {
                            coordinator.applyAppShieldForOngoingSession()
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.completedTasks = coordinator.completedReminderTasks
        }
    }
    
    
    // MARK: - Log Reminder Tasks
    
    private func logReminderTasks() {
        viewModel.completedTasks
    }
    
    
    // MARK: - SafeBottomAreaView
    
    struct SafeAreaBottomView: View {
        
        let name: String
        let timeIntervalRange: ClosedRange<Date>
        let sessionType: FocusSessionType
        let icon: Icon
        let shieldActivities: FamilyActivitySelection
        let phaseFactor: CGFloat
        
        var body: some View {
            VStack(alignment: .leading, spacing: 14) {
                SessionOverviewBottomEdgeView(name: name, viewType: .sheetOverview(timeIntervalRange), sessionType: sessionType, icon: icon)
                HStack(alignment: .center, spacing: 4) {
                    SessionOverviewBottomEdgeAccesoryView(viewInfo: .alarm(timeIntervalRange.lowerBound))
                    SessionOverviewBottomEdgeAccesoryView(viewInfo: .appSheild(shieldActivities))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 24)
            .padding(.horizontal, 24)
            .fixedSize(horizontal: false, vertical: true)
            .background(alignment: .bottom, content: {
                Rectangle()
                    .fill(Material.thin)
                    .mask(alignment: .top) {
                        LinearGradient(stops: [.init(color: Color.clear, location: 0), .init(color: Color.black, location: 0.2)], startPoint: .top, endPoint: .bottom)
                    }
                    .ignoresSafeArea(edges: .bottom)
            })
            .opacity((0...0.2).normalize(for: 1 - phaseFactor))
            .animation(nil, value: phaseFactor)
        }
    }
    
}


extension ClosedRange where Self.Bound == CGFloat {
    func normalize(for value: Self.Bound) -> Self.Bound {
        let min = lowerBound as Self.Bound
        let max = upperBound as Self.Bound
        let denom = max - min
        let num = value - min
        
        return num / denom
    }
}
