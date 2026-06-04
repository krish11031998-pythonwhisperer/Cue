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
    
    enum ViewState: Equatable {
        case idle
        case withReminder(ReminderModel)
        case transitioningBetweenReminders
    }
    
    @Environment(FocusCountdownRootViewModel.self) var viewModel
    @Environment(FocusTimerLaunchControlCoordinator.self) var coordinator
    @State private var frame: CGRect = .zero
    @State private var state: ViewState = .idle
    
    var isIdle: Bool {
        coordinator.state == .idle || coordinator.state == .reset
    }
    
    var body: some View {
        
        ZStack(alignment: .center) {
            FocusCountdownView(targetDuration: coordinator.timerDuration, mode: .asTimer, theme: Color.proSky, stateUpdateHandler: stateUpdateHandler(_:)) {
                Color.clear
                    .aspectRatio(1, contentMode: .fit)
                    .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { newValue in
                        self.frame = newValue
                    }
            }
            .environment(\.focusTimerStateFromCoordinator, coordinator.state)
            .opacity(isIdle ? 0.275 : 1)
            .blur(radius: isIdle ? 5 : 0)
            
            if coordinator.state == .idle || coordinator.state == .reset {
                switch state {
                case .idle:
                    EmptyView()
                case .withReminder(let reminderModel):
                    SelectedReminderView(reminderModel: reminderModel)
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
        .task(id: viewModel.selectedReminder) {
            guard case .withReminder(let reminderModel) = state else {
                self.state = .withReminder(viewModel.selectedReminder)
                return
            }
            guard reminderModel != viewModel.selectedReminder else { return }
            self.state = .transitioningBetweenReminders
            self.viewModel.panGestureTranslation = 0
            try? await Task.sleep(for: .milliseconds(0.5))
            withAnimation(.snappy) {
                self.state = .withReminder(viewModel.selectedReminder)
            }
        }
        .onChange(of: state, initial: false) { oldValue, newValue in
            guard case .withReminder = newValue else { return }
            coordinator.state = .idle
        }
    }
    
    
    // MARK: - State Updates
    
    private func stateUpdateHandler(_ timerState: FocusCountdownView.TimerState) {
        switch timerState {
        case .completed:
            coordinator.reset()
        case .resume:
            // Hide the safeBottomArea View
            break
        case .paused:
            // Do nothing for now
            break
        case .idle:
            break
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
        .environment(FocusCountdownRootViewModel(reminders: [.exampleOne(), .exampleTwo(), .exampleThree()]))
        .environment(FocusTimerLaunchControlCoordinator())
        .padding(.all, 20)
}
