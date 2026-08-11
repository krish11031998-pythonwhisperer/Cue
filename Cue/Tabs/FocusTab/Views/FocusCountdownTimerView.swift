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
                    SelectedTimerView(item: item)
                        .position(frame.center)
                        .frame(width: frame.width, height: frame.height, alignment: .center)
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
        
        var body: some View {
            ZStack(alignment: .center) {
                if coordinator.state == .idle || coordinator.state == .reset {
                    Color.clear
                } else {
                    FocusSessionTimeCountdownView(countdownViewType: countdownViewType, theme: theme, remainingTime: coordinator.remainingTimeDuration, isCompleted: false, icon: icon)
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
        let item: TimerType
        
        var body: some View {
            switch item {
            case .focus:
                VStack(alignment: .center, spacing: 0) {
                    Text("Focus")
                        .font(.title2.weight(.semibold))
                    
                    Text(coordinator.timerDuration.timerDurationString)
                        .contentTransition(.numericText(value: coordinator.timerDuration))
                        .animation(.easeInOut, value: coordinator.timerDuration)
                        .font(.largeTitle.weight(.bold))
                        .padding(.top, 16)
                }
#if NEW_COUNTDOWN_TIMER
                .foregroundColor(Color.proSky.foregroundTertiary)
#else
                .foregroundColor(.primary)
#endif
            case .reminder(let reminder):
                SelectedReminderView(reminderModel: reminder)
            }
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
                    .foregroundColor(.primary)
                
                Text(coordinator.timerDuration.timerDurationString)
                    .contentTransition(.numericText(value: coordinator.timerDuration))
                    .animation(.easeInOut, value: coordinator.timerDuration)
                    .font(.largeTitle.weight(.bold))
                #if NEW_COUNTDOWN_TIMER
                    .foregroundStyle(theme.foregroundTertiary)
                #else
                    .foregroundStyle(.primary)
                #endif
                    .padding(.top, 16)
                
                if !reminderModel.tasks.isEmpty {
                    Text("\(reminderModel.tasks.count) Tasks")
                        .font(.body.weight(.medium))
                        .padding(.init(top: 8, leading: 8, bottom: 8, trailing: 8))
                        .background(Material.thin, in: .capsule)
                        .padding(.top, 16)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
}

#Preview {
    FocusCountdownTimerView()
        .environment(FocusTimerRootViewModel(reminders: [.exampleOne(), .exampleTwo(), .exampleThree()]))
        .environment(FocusSessionCoordinator(alarmCoordinator: nil, liveActivityCoordinator: nil, appShieldCoordinator: nil))
        .padding(.all, 20)
}
