//
//  FocusCountdownTimerView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 31/05/2026.
//

import VanorUI
import SwiftUI
import Model

struct FocusCountdownTimerView: View {
    
    typealias TimerType = FocusTimerRootViewModel.TimerType
    
    enum ViewState: Equatable {
        case idle
        case withTimer(TimerType)
        case transitioningBetweenReminders
    }
    
    @Environment(FocusTimerRootViewModel.self) var viewModel
    @Environment(FocusSessionCoordinator.self) var coordinator
    @State private var frame: CGRect = .zero
    @State private var state: ViewState = .idle
    
    var isIdle: Bool {
        coordinator.state == .idle || coordinator.state == .reset
    }
    
    var countdownViewType: CountdownViewType {
        #if NEW_COUNTDOWN_TIMER
        return .circle
        #else
        return .circle
        #endif
    }
    
    var theme: LCHColor {
        switch viewModel.selectedTimerItem {
        case .focus:
            return Color.proSky
        case .reminder(let reminderModel):
            return .init(color: reminderModel.color)
        }
    }
    
    #if NEW_COUNTDOWN_TIMER
    var icon: Icon? {
        guard case .reminder(let reminderModel) = viewModel.selectedTimerItem else { return .symbol(.timer) }
        return .init(reminderModel.icon)
    }
    #endif
    
    var body: some View {
        
        ZStack(alignment: .center) {
            FocusCountdownView(countdownViewType: countdownViewType,
                               targetDuration: coordinator.timerDuration,
                               theme: theme) {
                InnerContent(countdownViewType: countdownViewType, theme: theme, icon: icon, frame: $frame)
            }
                               .environment(\.focusTimerStateFromCoordinator, coordinator.state.uiState)
                               .environment(\.focusTimerProgressFromCoordinator, coordinator.progress)
                               .opacity(isIdle ? 0.275 : 1)
                               .blur(radius: isIdle ? 5 : 0)
            
            if coordinator.state == .idle || coordinator.state == .reset {
                switch state {
                case .idle:
                    EmptyView()
                case .withTimer(let item):
                    SelectedTimerView(theme: theme, frame: frame, item: item)
                        .popIn(percent: viewModel.panGestureTranslation)
                        .transition(.popIn)
                case .transitioningBetweenReminders:
                    Color.clear
                        .frame(width: frame.width, height: frame.height, alignment: .center)
                }
            }
            
        }
        .task(id: viewModel.selectedTimerItem) {
            guard case .withTimer(let timer) = state else {
                self.state = .withTimer(viewModel.selectedTimerItem)
                return
            }
            guard timer != viewModel.selectedTimerItem else { return }
            self.state = .transitioningBetweenReminders
            self.viewModel.panGestureTranslation = 0
            try? await Task.sleep(for: .milliseconds(0.5))
            withAnimation(.snappy) {
                self.state = .withTimer(viewModel.selectedTimerItem)
            }
        }
        .onChange(of: state, initial: false) { oldValue, newValue in
            guard case .withTimer = newValue else { return }
        }
    }
    
    
    // MARK: - Focus
    
    private struct InnerContent: View {
        
        @Environment(FocusSessionCoordinator.self) var coordinator
        let countdownViewType: CountdownViewType
        let theme: LCHColor
        let icon: Icon?
        @Binding var frame: CGRect
        
        var font: FocusSessionTimeCountdownView.FontType {
            #if NEW_COUNTDOWN_TIMER
            return .custom(.bitcountMedium(style: .extraLargeTitle))
            #else
            return .defaultLargeTitle
            #endif
        }
        
        var body: some View {
            ZStack(alignment: .center) {
                if coordinator.state == .idle || coordinator.state == .reset {
                    Color.clear
                } else {
                    FocusSessionTimeCountdownView(countdownViewType: countdownViewType,
                                                  theme: theme,
                                                  remainingTime: coordinator.remainingTimeDuration,
                                                  isCompleted: false,
                                                  icon: icon,
                                                  font: font)
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { newValue in
                self.frame = newValue
            }
        }
        
    }
    
    // MARK: - Selected Timer View
    
    struct SelectedTimerView: View {
        
        @Environment(FocusSessionCoordinator.self) var coordinator
        @State private var childFrame: CGRect = .zero
        let namespace: NamedCoordinateSpace = .named("parentView")
        let theme: LCHColor
        let frame: CGRect
        let item: TimerType
        
        var chipType: FocusCountdownTimerView.InfoChipView.ChipType {
            switch coordinator.selectedTimerType {
            case .classic:
                return .classic
            case .pomodoro:
                return .pomodoro(sessionCount: coordinator.pomodoroSessionCount, breakDuration: coordinator.breakDuration)
            }
        }
        
        var body: some View {
            ZStack(alignment: .top) {
                
                if coordinator.numberOfTasks > 0 {
                    Chip(text: "\(coordinator.numberOfTasks) Tasks", theme: theme)
                        .position(x: childFrame.midX, y: childFrame.minY - 24)
                }
                
                Group {
                    switch item {
                    case .focus:
                        GeneralFocusSessionView(timerDuration: coordinator.timerDuration)
                    case .reminder(let reminder):
                        SelectedReminderView(reminderModel: reminder)
                    }
                }
                .onGeometryChange(for: CGRect.self, of: { $0.frame(in: namespace) }, action: { childFrame = $0 })
                .position(frame.center)
                
                InfoChipView(chipType: chipType, theme: theme)
                    .padding(.top, childFrame.maxY)
            }
            .frame(width: frame.width, height: frame.height, alignment: .center)
            .coordinateSpace(namespace)
        }
    }
    
    struct GeneralFocusSessionView: View {
        
        let timerDuration: TimeInterval
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                Text("Focus")
                    .font(.title2.weight(.semibold))
                
                Text(timerDuration.timerDurationString)
                    .contentTransition(.numericText(value: timerDuration))
                    .animation(.easeInOut, value: timerDuration)
                    #if NEW_COUNTDOWN_TIMER
                    .font(.bitcountMedium(style: .largeTitle))
                    #else
                    .font(.largeTitle.weight(.bold))
                    #endif
                    .padding(.top, 16)
            }
            #if NEW_COUNTDOWN_TIMER
            .foregroundColor(Color.proSky.foregroundTertiary)
            #else
            .foregroundColor(.primary)
            #endif
        }
    }
    
    // MARK: - Selected Reminder View
    
    struct SelectedReminderView: View {
        
        let reminderModel: ReminderModel
        @Environment(FocusSessionCoordinator.self) var coordinator
        
        var theme: LCHColor {
            .init(color: reminderModel.color)
        }
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                HStack(alignment: .center, spacing: 8) {
                    ReminderIconView(icon: .init(reminderModel.icon)!,
                                     foregroundColor: .primary,
                                     backgroundColor: theme.backgroundTertiary,
                                     font: .subheadline)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 32, alignment: .center)
                    Text(reminderModel.title)
                        .multilineTextAlignment(.center)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(theme.foregroundTertiary)
                }
                
                Text(coordinator.timerDuration.timerDurationString)
                    .contentTransition(.numericText(value: coordinator.timerDuration))
                    .animation(.easeInOut, value: coordinator.timerDuration)
                #if NEW_COUNTDOWN_TIMER
                    .font(.bitcountMedium(style: .largeTitle))
                    .foregroundStyle(theme.foregroundTertiary)
                #else
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)
                #endif
                    .padding(.top, 16)
            }
        }
    }
    
    
    // MARK: - Chip
    
    struct InfoChipView: View {
        
        enum ChipType: Equatable {
            case classic
            case pomodoro(sessionCount: Int, breakDuration: TimeInterval)
            
            var topPadding: CGFloat {
                switch self {
                case .classic:
                    return 16
                case .pomodoro:
                    return 8
                }
            }
        }
        
        let chipType: ChipType
        let theme: LCHColor
        
        var body: some View {
            if case .pomodoro(let sessionCount, let breakDuration) = chipType {
                HStack(alignment: .center, spacing: 8) {
                    Chip(text: "\(sessionCount) Sessions", theme: theme)
                    Chip(text: "Break: \(breakDuration.timerDurationString)", theme: theme)
                }
                .padding(.top, 8)
            } else {
                EmptyView()
            }
        }
    }
    
    struct Chip: View {
        let text: String
        let theme: LCHColor
        
        var body: some View {
            Text(text)
                .font(.caption.weight(.medium))
                .foregroundStyle(theme.foregroundSecondary)
                .padding(.init(top: 8, leading: 8, bottom: 8, trailing: 8))
                .background(theme.backgroundPrimary, in: .capsule)
        }
    }
}

#Preview {
    FocusCountdownTimerView()
        .environment(FocusTimerRootViewModel(reminders: [.exampleOne(), .exampleTwo(), .exampleThree()]))
        .environment(FocusSessionCoordinator(alarmCoordinator: nil, liveActivityCoordinator: nil, appShieldCoordinator: nil))
        .padding(.all, 20)
}
