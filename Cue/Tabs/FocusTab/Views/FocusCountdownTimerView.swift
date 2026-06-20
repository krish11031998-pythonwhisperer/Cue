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
    @Environment(FocusTimerLaunchControlCoordinator.self) var coordinator
    @State private var frame: CGRect = .zero
    @State private var state: ViewState = .idle
    
    var isIdle: Bool {
        coordinator.state == .idle || coordinator.state == .reset
    }
    
    var body: some View {
        
        ZStack(alignment: .center) {
            FocusCountdownView(targetDuration: coordinator.timerDuration, theme: Color.proSky) {
                ZStack(alignment: .center) {
                    if coordinator.state == .idle || coordinator.state == .reset {
                        Color.clear
                    } else {
                        FocusSessionTimeCountdownView(theme: Color.proSky, remainingTime: coordinator.remainingTimeDuration, isCompleted: false)
                    }
                }
                .aspectRatio(1, contentMode: .fit)
                .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { newValue in
                    self.frame = newValue
                }
            }
            .environment(\.focusTimerStateFromCoordinator, coordinator.state)
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
//            coordinator.state = .idle
        }
    }
    
    
    // MARK: - State Updates
    
//    private func stateUpdateHandler(_ timerState: FocusCountdownView.TimerState) {
//        switch timerState {
//        case .completed:
//            coordinator.reset()
//        case .resume:
//            // Hide the safeBottomArea View
//            break
//        case .paused:
//            // Do nothing for now
//            break
//        case .idle:
//            break
//        }
//    }
    
    
    // MARK: - Selected Timer View
    
    struct SelectedTimerView: View {
        
        @Environment(FocusTimerLaunchControlCoordinator.self) var coordinator
        let item: TimerType
        
        var body: some View {
            switch item {
            case .focus:
                VStack(alignment: .center, spacing: 0) {
                    Text("Focus")
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.primary)
                    
                    Text(coordinator.timerDuration.timerDurationString)
                        .contentTransition(.numericText(value: coordinator.timerDuration))
                        .animation(.easeInOut, value: coordinator.timerDuration)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.primary)
                        .padding(.top, 16)
                }
            case .reminder(let reminder):
                SelectedReminderView(reminderModel: reminder)
            }
        }
    }
    
    // MARK: - Selected Reminder View
    
    struct SelectedReminderView: View {
        
        let reminderModel: ReminderModel
        @Environment(FocusTimerLaunchControlCoordinator.self) var coordinator
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                HStack(alignment: .center, spacing: 8) {
                    ReminderIconView(icon: .init(reminderModel.icon)!,
                                     foregroundColor: .primary,
                                     backgroundColor: Color.proSky.backgroundSecondary,
                                     font: .subheadline)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 32, alignment: .center)
                    Text(reminderModel.title)
                        .multilineTextAlignment(.center)
                        .font(.title2.weight(.semibold))
                }
                    .foregroundColor(.primary)
                
                Text(coordinator.timerDuration.timerDurationString)
                    .contentTransition(.numericText(value: coordinator.timerDuration))
                    .animation(.easeInOut, value: coordinator.timerDuration)
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(.primary)
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
        .environment(FocusTimerLaunchControlCoordinator(alarmCoordinator: nil))
        .padding(.all, 20)
}
