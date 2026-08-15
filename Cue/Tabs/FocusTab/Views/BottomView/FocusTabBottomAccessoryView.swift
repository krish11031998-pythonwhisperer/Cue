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
    
    var theme: LCHColor {
        Color.proSky
    }
    
    private var transition: AnyTransition {
        .asymmetric(insertion: .scale(scale: 0.95, anchor: .center).combined(with: .opacity), removal: .scale(scale: 1.1).combined(with: .opacity))
    }
    
    var body: some View {
        ZStack {
            switch coordinator.state {
            case .idle, .reset:
                StartTimerButton(sessionAttributes: coordinator.sessionAttributes, action: coordinator.startTimer)
                    .transition(transition)
            case .start, .resume, .pause:
                OngoaingTimerControl(coordinator: coordinator, actionOnTap: coordinator.presentTaskSheet)
                    .transition(transition)
            }
        }
        .animation(.snappy, value: coordinator.state)
    }
    
    
    // MARK: - Start Timer Button
    
    struct StartTimerButton: View {
        
        let sessionAttributes: FocusSessionAttributes?
        let action: () -> Void
        
        var theme: LCHColor {
            if let color = sessionAttributes?.color {
                return color
            } else {
                return Color.proSky
            }
        }
        
        var body: some View {
            Text("Start Timer")
                .font(.headline)
                .foregroundStyle(theme.foregroundPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(alignment: .center) {
                    LinearGradient(colors: [theme.surfaceTertiary, theme.surfacePrimary], startPoint: .top, endPoint: .bottom)
                        .aspectRatio(contentMode: .fill)
                }
                .contentShape(Capsule())
                .onTapGesture(perform: action)
        }
    }
    
    
    // MARK: - Ongoing Timer Control
    
    struct OngoaingTimerControl: View {
        @Bindable var coordinator: FocusSessionCoordinator
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


#Preview {
    @Previewable @State var control = FocusSessionCoordinator(alarmCoordinator: nil, liveActivityCoordinator: nil, appShieldCoordinator: nil)
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
