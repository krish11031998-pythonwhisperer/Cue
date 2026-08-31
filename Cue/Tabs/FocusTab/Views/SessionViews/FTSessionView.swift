//
//  FTSessionView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 30/08/2026.
//

import SwiftUI
import VanorUI
import FamilyControls

struct FTSessionView<Content: View>: View {
    
    enum ViewType {
        case quickStart
        case activeSession
    }
    
    enum Presentation: Identifiable {
        case appBlock(Callback?)
        case pomodoroSessionEditor
        
        var id: String {
            switch self {
            case .pomodoroSessionEditor:
                return "pomodoroSessionEditor"
            case .appBlock:
                return "appBlock"
            }
        }
    }
    
    @Environment(\.dismiss) var dismiss
    @State private var sheetPresentation: Presentation? = nil
    @Bindable var coordinator: FocusSessionCoordinator
    let viewType: ViewType
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        NavigationView {
            content()
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemSymbol: .chevronDown)
                                .font(.headline)
                        }
                        .buttonStyle(.plain)
                    }
                }
        }
        .safeAreaBar(edge: .bottom, alignment: .center, spacing: 8) {
            FloatingFocusTimerFooterView(coordinator: coordinator, viewType: viewType) { completion in
                presentAppBlock(completion)
            } presentAction: { sessionType in
                presentAction(sessionType: sessionType)
            }
        }
        .sheet(isPresented: $coordinator.showTasksSheet) {
            OngoingSessionOverviewSheet()
                .environment(coordinator)
                .presentationContentInteraction(.resizes)
                .interactiveDismissDisabled(true)
                .presentationDragIndicator(.hidden)
        }
        .sheet(item: $sheetPresentation) { sheet in
            switch sheet {
            case .pomodoroSessionEditor:
                PomodoroSessionEditorView(coordinator: coordinator)
                    .fittedPresentationDetent()
            case .appBlock(let completion):
                BlockAppView(selectedActivities: coordinator.shieldActivities) {
                    self.coordinator.shieldActivities = $0
                    self.coordinator.appShieldIsOn = !$0.isEmpty
                    completion?()
                }
                .presentationDetents([.fraction(1)])
            }
        }
    
    }

    // MARK: - Floating Focus Timer View
    
    struct FloatingFocusTimerFooterView: View {
        @Environment(\.dismiss) var dismiss
        @Bindable private var coordinator: FocusSessionCoordinator
        let viewType: ViewType
        let presentAppBlock: (Callback?) -> Void
        let presentAction: (FocusTimerType) -> Void
        
        init(coordinator: FocusSessionCoordinator,
             viewType: ViewType,
             presentAppBlock: @escaping (Callback?) -> Void,
             presentAction: @escaping (FocusTimerType) -> Void) {
            self.viewType = viewType
            self.coordinator = coordinator
            self.presentAppBlock = presentAppBlock
            self.presentAction = presentAction
        }
        
        var body: some View {
            VStack(alignment: .center, spacing: 8) {
                FTSessionInfoFooterView(viewType: viewType, coordinator: coordinator, presentAppBlock: presentAppBlock, presentAction: presentAction)
                FTSessionControlFooterView(viewType: viewType, coordinator: coordinator)
            }
            .padding(.horizontal, 16)
        }
        
        
        // MARK: FTSessionInfoFooterView
        
        struct FTSessionInfoFooterView: View {
            let viewType: ViewType
            @Bindable var coordinator: FocusSessionCoordinator
            let presentAppBlock: (Callback?) -> Void
            let presentAction: (FocusTimerType) -> Void
            
            // NOTE: Must stay a computed property so every `coordinator` read below happens
            // during `body` evaluation — that is what keeps SwiftUI observation alive for
            // appShieldIsOn / isAlarmOn / currentSessionIndex.
            private var ongoingModel: FTOSInfoView.Model {
                let sessionType: FocusSessionType
                switch coordinator.selectedTimerType {
                case .classic:
                    sessionType = .classic
                case .pomodoro:
                    sessionType = .pomodoro(currentIndex: coordinator.currentSessionIndex,
                                            total: coordinator.pomodoroSessionCount)
                }

                return .init(
                    name: coordinator.sessionAttributes?.name,
                    icon: coordinator.sessionAttributes?.icon,
                    sessionType: sessionType,
                    appShieldIsOn: coordinator.appShieldIsOn,
                    isAlarmOn: coordinator.isAlarmOn,
                    enableAppShield: {
                        presentAppBlock {
                            coordinator.applyAppShieldForOngoingSession()
                        }
                    },
                    disableAppShield: { coordinator.removeAppShield() },
                    enableAlarm: { coordinator.setupAlarmForOngoingSesion() },
                    disableAlarm: { coordinator.cancelScheduledAlarm() }
                )
            }

            // NOTE: computed, for the same observation reason as `ongoingModel` above.
            private var launchControlModel: FTLaunchControl.Model {
                .init(
                    selectedTimerType: coordinator.selectedTimerType,
                    timerDuration: coordinator.timerDuration,
                    timerDurationString: coordinator.timerDurationAsString,
                    sliderProgress: coordinator.startingDurationForSlider,
                    pomodoroDescription: coordinator.pomodoroSessionDescription,
                    appShieldIsOn: coordinator.appShieldIsOn,
                    isAlarmOn: coordinator.isAlarmOn,
                    canShowAlarm: coordinator.canShowAlarm,
                    selectTimerType: { coordinator.selectedTimerType = $0 },
                    increment: coordinator.increment,
                    decrement: coordinator.decrement,
                    updateDurationFromSlider: { coordinator.sliderFractionToTimeDuration(fraction: $0) },
                    presentBlockAppsSheet: { presentAppBlock(nil) },
                    presentPomodoroSetupSheet: {
                        // Present Sheet
                        presentAction(coordinator.selectedTimerType)
                    },
                    toggleAlarm: { coordinator.toggleAlarm() },
                    turnOffAlarm: { coordinator.isAlarmOn = false },
                    setAlarmEndOfSession: { coordinator.updateAlarmAt(.endOfSession) },
                    setAlarmBetweenSessions: { coordinator.updateAlarmAt(.betweenPomodoroSessions) },
                    checkIfCanSetAlarm: { await coordinator.checkIfCanSetAlarm() }
                )
            }
            
            var body: some View {
                switch viewType {
                case .quickStart:
                    ZStack(alignment: .center) {
                        switch coordinator.state {
                        case .idle, .reset:
                            FTLaunchControl(model: launchControlModel)
                                .transition(.popIn)
                        case .pause, .resume, .start:
                            FTOSInfoView(model: ongoingModel)
                                .transition(.popIn)
                        }
                    }
                    .animation(.easeInOut, value: coordinator.state)
                    .fixedSize(horizontal: false, vertical: true)
                case .activeSession:
                    FTOSInfoView(model: ongoingModel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        
        // FTSessionControlFooterView
        
        struct FTSessionControlFooterView: View {
            @Environment(\.theme) var theme
            @Environment(\.dismiss) var dismiss

            let viewType: ViewType
            @Bindable var coordinator: FocusSessionCoordinator
            
            // NOTE: computed, so every `coordinator` read happens during `body` evaluation —
            // that is what keeps SwiftUI observation alive for `state` / `informationString`.
            private var ongoingSessionControlModel: FTOngoingSessionControl.Model {
                .init(
                    informationString: coordinator.informationString,
                    isRunning: coordinator.state == .start || coordinator.state == .resume,
                    togglePlayPause: {
                        if coordinator.state == .resume || coordinator.state == .start {
                            coordinator.pauseTimer()
                        } else if coordinator.state == .pause {
                            coordinator.resumeTimer()
                        }
                    },
                    stop: {
                        coordinator.cancelAndReset()
                        if viewType == .activeSession {
                            dismiss()
                        }
                    },
                    onTap: { coordinator.presentTaskSheet() }
                )
            }
            
            var body: some View {
                switch viewType {
                case .quickStart:
                    ZStack(alignment: .center) {
                        switch coordinator.state {
                        case .idle, .reset:
                            FTStartTimerButton(model: .init(viewMode: .bottomFloatingView, action: coordinator.startTimer))
                                .transition(.opacity)
                        case .pause, .resume, .start:
                            FTOngoingSessionControl(model: ongoingSessionControlModel)
                                .padding(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
                                .glassEffect(.regular, in: .capsule)
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut, value: coordinator.state)
                    .fixedSize(horizontal: false, vertical: true)
                case .activeSession:
                    FTOngoingSessionControl(model: ongoingSessionControlModel)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .glassEffect(.regular, in: .capsule)
                }
            }
        }
        
        
    }
    
    
    
    // MARK: - Actions
    
    func presentAppBlock(_ completion: Callback?) {
        Task { @MainActor in
            do {
                guard try await CueAppBlockManager.retrieveAuthorization() == .approved else { return }
                self.sheetPresentation = .appBlock(completion)
            } catch {
            #warning("Present an error alert")
                print("(ERROR) While retrieving Authorization for App block: ", error.localizedDescription)
            }
        }
    }
    
    private func presentAction(sessionType: FocusTimerType) {
        switch sessionType {
        case .classic:
            // Do nothing for now
            break
        case .pomodoro:
            sheetPresentation = .pomodoroSessionEditor
        }
    }
    
}

