//
//  FTQuickStartView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 01/06/2026.
//

import SwiftUI
import VanorUI
import Model
import FamilyControls

extension FamilyActivitySelection {
    var isEmpty: Bool {
        self.applications.isEmpty && self.categories.isEmpty && self.webDomains.isEmpty
    }
}

struct FocusCountdownTopGradient: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: .init(x: rect.minX, y: rect.minY))
            path.addLine(to: .init(x: rect.maxX, y: rect.minY))
            path.addQuadCurve(to: .init(x: rect.minX, y: rect.minY), control: .init(x: rect.midX, y: rect.maxY * 0.45))
        }
    }
}

struct FTQuickStartView: View {

    @Bindable private var coordinator: FocusSessionCoordinator
    @State private var viewModel: FTQuickStartViewModel = .init()
    let reminders: [ReminderModel]
    @Environment(\.colorScheme) var colorScheme
    
    init(coordinator: FocusSessionCoordinator, reminders: [ReminderModel]) {
        self.coordinator = coordinator
        self.reminders = reminders
    }
    
    var appTheme: LCHColor {
        Color.proSky
    }
    
    private func radialGradient(width: CGFloat) -> RadialGradient {
        switch colorScheme {
        case .light:
            RadialGradient(colors: [appTheme.baseColor.opacity(0.5), appTheme.baseColor.opacity(0.3), appTheme.baseColor.opacity(0.1), appTheme.baseColor.opacity(0)], center: .center, startRadius: 0, endRadius: width)
        case .dark:
            RadialGradient(colors: [appTheme.baseColor.opacity(1), appTheme.baseColor.opacity(0.5), appTheme.baseColor.opacity(0.2), appTheme.baseColor.opacity(0)], center: .center, startRadius: 0, endRadius: width)
        @unknown default:
            RadialGradient(colors: [appTheme.baseColor.opacity(0.5), appTheme.baseColor.opacity(0.3), appTheme.baseColor.opacity(0.1), appTheme.baseColor.opacity(0)], center: .center, startRadius: 0, endRadius: width)
        }
    }
    
    private var defaultColor: Color {
        switch colorScheme {
        case .light:
            Color.waveformColorOne
        case .dark:
            Color.waveformDarkColorOne
        @unknown default:
            Color.waveformColorOne
        }
    }
    
    private var gestureRecognizerEnabled: Bool {
        coordinator.state == .idle || coordinator.state == .reset
    }
    
    private var linearGradientBackground: some View {
        let mainColor: LCHColor
        switch viewModel.selectedTimerItem {
        case .focus:
            mainColor = .init(color: defaultColor)
        case .reminder(let reminderModel):
            mainColor = .init(color: reminderModel.color)
        }
        
        return LinearGradient(stops: [
            .init(color: mainColor.backgroundPrimary, location: 0),
            .init(color: mainColor.backgroundPrimary.opacity(0.6), location: 0.1),
            .init(color: mainColor.backgroundPrimary.opacity(0.3), location: 0.2),
            .init(color: mainColor.backgroundPrimary.opacity(0.1), location: 0.5)],
                       startPoint: .top,
                       endPoint: .bottom)
    }
    
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            
            ZStack(alignment: .center) {
                Color.cueItBackground
                    .ignoresSafeArea(edges: .vertical)
                
                FocusCountdownTimerView()
                    .environment(viewModel)
                    .environment(coordinator)
                    .padding(.horizontal, 8)
                    .position(x: size.width.half, y: size.width * 0.7)
            }
        }
        .sensoryFeedback(.selection, trigger: viewModel.selectedTimerItem)
        .gesture(DragPopGesture(isEnabled: gestureRecognizerEnabled, translation: dragGestureHandler, hasEnded: hasEnded))
        .safeAreaBar(edge: .top, alignment: .center, spacing: 8) {
            FocusReminderCarouselSelectorView(selectedItem: viewModel.selectedTimerItem, items: viewModel.timerItems)
                .fixedSize(horizontal: false, vertical: true)
                .disabled(true)
        }
        .safeAreaBar(edge: .bottom, alignment: .center, spacing: 8) {
            FloatingFocusTimerFooterView(viewModel: viewModel, coordinator: coordinator)
        }
        .sheet(item: $viewModel.sheetPresentation) { sheet in
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
        .sheet(isPresented: $coordinator.showTasksSheet, onDismiss: {
            self.viewModel.sessionTaskPresentationDetent = .medium
        }) {
            OngoingSessionOverviewSheet(selectedPresentationDetent: viewModel.sessionTaskPresentationDetent)
                .environment(coordinator)
                .presentationDetents([.medium, .large], selection: $viewModel.sessionTaskPresentationDetent)
                .presentationContentInteraction(.resizes)
                .interactiveDismissDisabled(true)
                .presentationDragIndicator(.hidden)
        }
        .onChange(of: viewModel.selectedTimerItem, initial: true) { _, newValue in
            coordinator.reminderModel = viewModel.selectedReminder()
            coordinator.sessionAttributes = viewModel.focusSessionAttributes()
            coordinator.shieldConfiguration = viewModel.appShieldConfiguration()
        }
        .onChange(of: reminders, initial: true) { oldValue, newValue in
            viewModel.updateWithReminders(newValue)
        }
        .environment(\.theme, viewModel.selectedTimerItem.theme)
    }
    
    private func dragGestureHandler(_ point: CGPoint) {
        let x = point.x
        guard abs(x) > 0 else {
            withAnimation(.snappy) {
                viewModel.panGestureTranslation = 0
            }
            return
        }
        let diff = min(1, max(0, abs(x)/FTQuickStartViewModel.translationsXThreshold))
        viewModel.panGestureTranslation = diff
    }
    
    private func hasEnded(_ point: CGPoint) {
        let x = point.x
        guard abs(x) > FTQuickStartViewModel.translationsXThreshold else {
            withAnimation(.snappy) {
                self.viewModel.panGestureTranslation = 0
            }
            return
        }
        viewModel.updateSelectedReminder(forwards: x < 0, backwards: x > 0)
    }
    
    
    // MARK: - Floating Focus Timer View
    
    struct FloatingFocusTimerFooterView: View {
        
        @Bindable private var viewModel: FTQuickStartViewModel
        @Bindable private var coordinator: FocusSessionCoordinator
        
        init(viewModel: FTQuickStartViewModel, coordinator: FocusSessionCoordinator) {
            self.viewModel = viewModel
            self.coordinator = coordinator
        }

        // NOTE: Must stay a computed property so every `coordinator` read below happens
        // during `body` evaluation — that is what keeps SwiftUI observation alive for
        // appShieldIsOn / isAlarmOn / currentSessionIndex.
        private var ongoingModel: FTOngoingSessionFloatingView.Model {
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
                    viewModel.presentAppBlock {
                        coordinator.applyAppShieldForOngoingSession()
                    }
                },
                disableAppShield: { coordinator.removeAppShield() },
                enableAlarm: { coordinator.setupAlarmForOngoingSesion() },
                disableAlarm: { coordinator.cancelScheduledAlarm() }
            )
        }

        var body: some View {
            #if NEW_COUNTDOWN_TIMER
            VStack(alignment: .center, spacing: 8) {
                switch coordinator.state {
                case .idle, .reset:
                    FocusTimerLaunchControl(coordinator: coordinator) {
                        // Present Sheet
                        print("(DEBUG) present sheet with reminders")
                        viewModel.presentAction(sessionType: coordinator.selectedTimerType)
                    } presentBlockAppsSheet: {
                        viewModel.presentAppBlock(nil)
                    }
                    .transition(.popIn)
                    .fixedSize(horizontal: false, vertical: true)

                case .pause, .resume, .start:
                    FTOngoingSessionFloatingView(model: ongoingModel)
                     .transition(.popIn)
                     .fixedSize(horizontal: false, vertical: true)
                }

                FloatingSecondaryView(coordinator: coordinator)
            }
            .padding(.horizontal, 16)
            #else
            ZStack(alignment: .center) {
                switch coordinator.state {
                case .idle, .reset:
                    FocusTimerLaunchControl(coordinator: coordinator) {
                        // Present Sheet
                        print("(DEBUG) present sheet with reminders")
                        viewModel.presentAction(sessionType: coordinator.selectedTimerType)
                    } presentBlockAppsSheet: {
                        viewModel.presentAppBlock(nil)
                    }
                    .transition(.popIn)
                case .pause, .resume, .start:
                    FTOngoingSessionFloatingView(model: ongoingModel)
                     .transition(.popIn)
                }
            }
            .padding(.bottom, 8)
            .padding(.horizontal, 20)
            .fixedSize(horizontal: false, vertical: true)
            #endif
        }
    }
    
    
    
    #if NEW_COUNTDOWN_TIMER
    // MARK: FloatingBottomView
    
    struct FloatingSecondaryView: View {
        var coordinator: FocusSessionCoordinator
        @Environment(\.theme) var theme
        
        var body: some View {
            switch coordinator.state {
            case .idle, .reset:
                Button {
                    // Start Timer
                    coordinator.startTimer()
                } label: {
                    Text("Start Timer")
                        .font(.headline)
                        .foregroundStyle(theme.foregroundPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .background(alignment: .center) {
                            LinearGradient(colors: [theme.surfaceTertiary, theme.surfacePrimary], startPoint: .top, endPoint: .bottom)
                                .aspectRatio(contentMode: .fill)
                        }
                }
                .controlSize(.large)
            case .pause, .resume, .start:
                OngoingTimerControl(coordinator: coordinator) {
                    coordinator.presentTaskSheet()
                }
            }
        }
        
        struct OngoingTimerControl: View {
            var coordinator: FocusSessionCoordinator
            let actionOnTap: Callback
            
            var playPauseButtonSybmol: SFSymbol {
                switch coordinator.state {
                case .idle, .pause, .reset:
                    return .playFill
                case .start, .resume:
                    return .pauseFill
                }
            }
            
            var body: some View {
                HStack(alignment: .center, spacing: 0) {
                    Text(coordinator.informationString)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack(alignment: .center, spacing: 8) {
                        LaunchControlButton(symbol: .same(playPauseButtonSybmol), size: .small) {
                            if coordinator.state == .resume || coordinator.state == .start {
                                coordinator.pauseTimer()
                            } else if coordinator.state == .pause {
                                coordinator.resumeTimer()
                            }
                        }
                        
                        LaunchControlButton(symbol: .same(.stopFill), size: .small) {
                            // Need to implement stop
                            coordinator.cancelAndReset()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .frame(maxHeight: .infinity, alignment: .center)
                .contentShape(Capsule())
                .onTapGesture {
                    coordinator.presentTaskSheet()
                }
            }
            
        }
    }
    
    
    #endif
    
}

#Preview {
    @Previewable @State var coordinator: FocusSessionCoordinator = .init(alarmCoordinator: nil, liveActivityCoordinator: nil, appShieldCoordinator: nil, storeCoordinator: nil)
    FTQuickStartView(coordinator: coordinator, reminders: [.exampleOne(), .exampleTwo(), .exampleThree(), .exampleFour()])
        .safeAreaBar(edge: .bottom) {
            FocusTimerLaunchControl(coordinator: coordinator) {
                //
            } presentBlockAppsSheet: {
                //
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20)
        }
}
