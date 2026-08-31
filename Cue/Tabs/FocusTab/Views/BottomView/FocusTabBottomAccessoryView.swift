//
//  FocusTabBottomAccessoryView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 30/04/2026.
//

import SwiftUI
import VanorUI

struct FocusTabBottomAccessoryView: View {
    
    @Bindable var coordinator: FocusSessionCoordinator
    @Environment(\.tabViewBottomAccessoryPlacement) var tabBarPlacement
    
    init(coordinator: FocusSessionCoordinator) {
        self.coordinator = coordinator
    }
    
    private var transition: AnyTransition {
        .asymmetric(insertion: .scale(scale: 0.95, anchor: .center).combined(with: .opacity), removal: .scale(scale: 1.1).combined(with: .opacity))
    }

    // The two call sites below differ only in their action, so this takes it as a
    // parameter. Called from `body`, so the `sessionAttributes` read stays observed.
    private func startTimerButtonModel(action: @escaping () -> Void) -> FTStartTimerButton.Model {
        .init(viewMode: .bottomTabAccessory, action: action)
    }

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
            stop: { coordinator.cancelAndReset() },
            onTap: { coordinator.presentTaskSheet() }
        )
    }

    var body: some View {
        ZStack {
            switch coordinator.state {
            case .idle, .reset:
                #if NEW_COUNTDOWN_TIMER
                FTStartTimerButton(model: startTimerButtonModel {
                    NotificationCenter.default.post(name: .presentQuickStart, object: nil)
                })
                #else
                FTStartTimerButton(model: startTimerButtonModel(action: coordinator.startTimer))
                    .transition(transition)
                #endif
            case .start, .resume, .pause:
                FTOngoingSessionControl(model: ongoingSessionControlModel)
                    .transition(transition)
            }
        }
        .animation(.snappy, value: coordinator.state)
    }
}


#Preview {
    @Previewable @State var control = FocusSessionCoordinator.previawableSessionCoordinator
    FocusTabBottomAccessoryView(coordinator: control)
        .environment(control)
        .clipShape(Capsule())
        .glassEffect(.regular, in: .capsule)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, alignment: .center)
        .frame(height: 54)
        .task {
            control.timerDuration = 10 * 60
        }
}
