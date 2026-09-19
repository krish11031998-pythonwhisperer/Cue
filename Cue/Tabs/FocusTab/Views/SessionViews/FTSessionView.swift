//
//  FTSessionView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 30/08/2026.
//

import SwiftUI
import VanorUI
import FamilyControls
import TipKit

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
    
    @Environment(SubscriptionManager.self) var subscriptionManager
    @Environment(\.dismiss) var dismiss
    @State private var sheetPresentation: Presentation? = nil
    @State private var alertError: AlertError? = nil
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
                subscriptionManager.proUserAction {
                    presentAppBlock(completion)
                }
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
        .cueAlert(alert: $alertError)
        .paywallPresentation()
        // Launch-control tips. Swap `foregroundSecondary` -> `foregroundTertiary` to compare.
        .tipViewStyle(.next(tint: Color.proSky.foregroundSecondary))
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
            
            @Environment(SubscriptionManager.self) var subscriptionManager
            /// Ordered so the launch-control tips appear one at a time instead of four popovers at once.
            @State private var launchControlTips = TipGroup(.ordered) {
                SessionDurationTip()
                BlockAppsTip()
                FocusTimerTypeTip()
                SessionAlarmTip()
            }
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
                    selectTimerType: { timerType in
                        // Classic stays free, so a lapsed user can always switch back to it.
                        subscriptionManager.proUserAction(isProFeature: timerType == .pomodoro) {
                            coordinator.selectedTimerType = timerType
                        }
                    },
                    increment: coordinator.increment,
                    decrement: coordinator.decrement,
                    updateDurationFromSlider: { coordinator.sliderFractionToTimeDuration(fraction: $0) },
                    presentBlockAppsSheet: {
                        subscriptionManager.proUserAction {
                            presentAppBlock(nil)
                        }
                    },
                    presentPomodoroSetupSheet: {
                        // Present Sheet
                        presentAction(coordinator.selectedTimerType)
                    },
                    toggleAlarm: {
                        subscriptionManager.proUserAction {
                            coordinator.toggleAlarm()
                        }
                    },
                    turnOffAlarm: { coordinator.isAlarmOn = false },
                    setAlarmEndOfSession: { coordinator.updateAlarmAt(.endOfSession) },
                    setAlarmBetweenSessions: { coordinator.updateAlarmAt(.betweenPomodoroSessions) },
                    checkIfCanSetAlarm: { await coordinator.checkIfCanSetAlarm() },
                    // `currentTip` is one of these at a time; the other three casts give nil.
                    tips: .init(duration: launchControlTips.currentTip as? SessionDurationTip,
                                appShield: launchControlTips.currentTip as? BlockAppsTip,
                                timerType: launchControlTips.currentTip as? FocusTimerTypeTip,
                                alarm: launchControlTips.currentTip as? SessionAlarmTip)
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
                switch try await CueAppBlockManager.retrieveAuthorization() {
                case .notDetermined:
                    break
                case .denied:
                    self.alertError = .deniedAppBlock
                case .approved, .approvedWithDataAccess:
                    self.sheetPresentation = .appBlock(completion)
                @unknown default:
                    self.alertError = .unknown
                }
            } catch let appBlockError as CueAppBlockManager.Error {
                switch appBlockError {
                case .deniedAccess:
                    self.alertError = .deniedAppBlock
                case .unknownStatus:
                    self.alertError = .unknown
                }
            } catch {
                self.alertError = .unknown
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

// MARK: - Alert

extension FTSessionView {
    @MainActor
    enum AlertError: Error, LocalizedError, CueAlertError {
        case deniedAppBlock
        case unknown
        
        var buttonTitle: String? {
            switch self {
            case .deniedAppBlock:
                return "Enable Screen Time Restrictions"
            case .unknown:
                return nil
            }
        }
        
        var actions: [CueAlertAction] {
            switch self {
            case .deniedAppBlock:
                return [.customAction(buttonTitle!, {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }), .cancel]
            case .unknown:
                return [.ok]
            }
        }
        
        var errorDescription: String? {
            switch self {
            case .deniedAppBlock:
                return "Denied Screen Time Restrictions"
            case .unknown:
                return "Unknown Error"
            }
        }
        
        var failureReason: String? {
            switch self {
            case .deniedAppBlock:
                return "You denied access for Screen Time Restrictions"
            case .unknown:
                return "Something Wrong happened, Try again later."
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .deniedAppBlock:
                return "Tap on '\(buttonTitle ?? "Action Below")'"
            case .unknown:
                return nil
            }
        }
    }
}
