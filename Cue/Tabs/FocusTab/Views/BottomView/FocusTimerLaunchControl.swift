//
//  FocusTimerLaunchControl.swift
//  Cue
//
//  Created by Krishna Venkatramani on 30/04/2026.
//

import SwiftUI
import VanorUI

fileprivate extension FocusTimerType {
    var buttonAttributedTitle: AttributedString {
        let title: AttributedString = .init(title + "\n", attributes: .init([.font: UIFont.preferredFont(for: .headline)]))
        let message: AttributedString = .init(description, attributes: .init([.font: UIFont.preferredFont(for: .caption2)]))
        return title + message
    }
}

fileprivate extension FocusSessionCoordinator {
    static let hourMark: TimeInterval = 3_600
    /// First 12 steps is the first hour , the rest step is 1 hour each.
    static let firstHourInFraction: CGFloat = 12 / 35
    static let fractionPerStep: CGFloat = 1 / 35
    
    var timerDurationString: String {
        timerDuration.timerDurationString
    }
    
    var startingDurationForSlider: CGFloat {
        if timerDuration < Self.hourMark {
            let factor = self.timerDuration / (5 * 60)
            print("(DEBUG) factor: ", factor)
            return factor / 35
        } else {
            let hour = timerDuration / Self.hourMark
            return Self.firstHourInFraction + (hour / 23)
        }
    }
    
    func increment() {
        if timerDuration >= Self.hourMark {
            timerDuration += 60 * 60
        } else {
            timerDuration += 5 * 60
        }
    }
    
    func decrement() {
        if timerDuration > Self.hourMark {
            timerDuration -= 60 * 60
        } else {
            timerDuration = max(1 * 60, timerDuration - 5 * 60)
        }
    }
    
    func sliderFractionToTimeDuration(fraction: CGFloat) {
        let stepForFraction = (fraction / Self.fractionPerStep).rounded(.toNearestOrAwayFromZero)
        if fraction < Self.firstHourInFraction {
            timerDuration = max(1 * 60, stepForFraction * 5 * 60)
        } else {
            timerDuration = (stepForFraction - 11) * 60 * 60
        }
    }
    
    
    // MARK: - Pomodoro Sessio Related Helpers
    
    var pomodoroSessionDurationString: String {
        timerDuration.timerDurationString
    }
    
    var pomodoroBreakDurationString: String {
        breakDuration.timerDurationString
    }
    
    var pomodoroSessionDescription: String {
        "\(pomodoroSessionDurationString) - \(pomodoroBreakDurationString) x \(pomodoroSessionCount)"
    }
}

struct FocusTimerLaunchControl: View {
    
    @Namespace var animation
    @Bindable private var coordinator: FocusSessionCoordinator
    @State private var expandTimeArc: Bool = false
    @State private var presentTimerSelectionMenu: Bool = false
    let presentReminderSelectionSheet: () -> Void
    let presentBlockAppsSheet: () -> Void
    
    init(coordinator: FocusSessionCoordinator, presentReminderSelectionSheet: @escaping () -> Void, presentBlockAppsSheet: @escaping () -> Void) {
        self.coordinator = coordinator
        self.presentReminderSelectionSheet = presentReminderSelectionSheet
        self.presentBlockAppsSheet = presentBlockAppsSheet
    }
    
    var body: some View {
        ZStack(alignment: .center) {
            switch coordinator.selectedTimerType {
            case .classic:
                ClassicSessionLaunchControlView(coordinator: coordinator, presentBlockAppSheet: presentBlockAppsSheet)
                    .transition(.blurReplace)
            case .pomodoro:
                PomodoroSessionLaunchControlView(coordinator: coordinator, presentPomodoroSetupSheet: presentReminderSelectionSheet, presentBlockAppSheet: presentBlockAppsSheet)
                    .transition(.blurReplace)
            }
        }
        .animation(.snappy(duration: 0.3, extraBounce: 0.1), value: coordinator.selectedTimerType)
        .frame(minHeight: 44)
        .sensoryFeedback(.levelChange, trigger: coordinator.timerDuration)
        .task {
            await coordinator.checkIfCanSetAlarm()
        }
    }
    
    
    // MARK: - Child View
    
    
    // MARK: BaseLaunchControlView
    
    struct BaseLaunchControlView<TimestampView: View>: View {
        
        @Bindable var coordinator: FocusSessionCoordinator
        let presentBlockAppSheet: () -> Void
        @ViewBuilder
        var timestamp: () -> TimestampView
        
        var body: some View {
            HStack(alignment: .center, spacing: 8) {
                timestamp()
                    .frame(maxHeight: .infinity, alignment: .center)
                    .containerRelativeFrame(.horizontal) { width, _ in
                        width * 0.4
                    }
                HStack(alignment: .center, spacing: 8) {
                    LaunchControlButton(image: .lockIphone, size: .capsule, action: presentBlockAppSheet)
                    
                    LaunchControlButton(image: coordinator.selectedTimerType.icon, size: .capsule, menu: {
                        ForEach(FocusTimerType.allCases.reversed()) { focusTimerType in
                            Button {
                                // button Action
                                coordinator.selectedTimerType = focusTimerType
                            } label: {
                                Text(focusTimerType.title)
                                Text(focusTimerType.description)
                                Image(systemSymbol: focusTimerType.icon)
                            }
                        }
                    })
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    LaunchControlButton(image: .alarmWavesLeftAndRight, size: .capsule) {
                        // Want an alarm
                        coordinator.toggleAlarm()
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .environment(\.launchControlButtonIsSelected, coordinator.isAlarmOn)
                    .disabled(!coordinator.canShowAlarm)
                }
            }
        }
    }
    
    
    // MARK: ClassicSessionLaunchControlView
    
    struct ClassicSessionLaunchControlView: View {
        
        @Namespace private var animation
        @Bindable var coordinator: FocusSessionCoordinator
        @State private var expandTimeArc: Bool = false
        let presentBlockAppSheet: () -> Void
        
        init(coordinator: FocusSessionCoordinator, presentBlockAppSheet: @escaping () -> Void) {
            self.coordinator = coordinator
            self.presentBlockAppSheet = presentBlockAppSheet
        }
        
        var body: some View {
            ZStack(alignment: .center) {
                if !expandTimeArc {
                    BaseLaunchControlView(coordinator: coordinator, presentBlockAppSheet: presentBlockAppSheet) {
                        HStack(alignment: .center, spacing: 8) {
                            LaunchControlButton(image: .minus, size: .small, action: coordinator.decrement)
                            
                            LaunchControlTimeView(duration: coordinator.timerDuration, durationString: coordinator.timerDurationString)
                                .matchedGeometryEffect(id: "launchControlTime", in: animation, properties: .frame, anchor: .leading, isSource: !expandTimeArc)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    expandTimeArc.toggle()
                                }
                            
                            LaunchControlButton(image: .plus, size: .small, action: coordinator.increment)
                        }
                    }
                } else {
                    LaunchControlSliderView(animation: animation, coordinator: coordinator, expandTimeArc: $expandTimeArc)
                }
            }
            .animation(.snappy(duration: 0.35, extraBounce: 0.1), value: expandTimeArc)
            
        }
    }
    
    
    // MARK: PomodoroSessionLaunchControlView
    
    struct PomodoroSessionLaunchControlView: View {
        
        @Bindable var coordinator: FocusSessionCoordinator
        let presentPomodoroSetupSheet: () -> Void
        let presentBlockAppSheet: () -> Void
        
        var body: some View {
            BaseLaunchControlView(coordinator: coordinator, presentBlockAppSheet: presentBlockAppSheet) {
                Button (action: presentPomodoroSetupSheet) {
                    PomodoroLaunchControlTimeView(durationDescriptionString: coordinator.pomodoroSessionDescription)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    
    // MARK: - LaunchControlSliderView
    
    struct LaunchControlSliderView: View {
        
        var animation: Namespace.ID
        @Bindable var coordinator: FocusSessionCoordinator
        @Binding var expandTimeArc: Bool
        
        
        var body: some View {
            HStack(alignment: .center, spacing: 8) {
                LaunchControlTimeView(duration: coordinator.timerDuration,
                                      durationString: coordinator.timerDurationString)
                .matchedGeometryEffect(id: "launchControlTime", in: animation, properties: .frame, anchor: .leading, isSource: expandTimeArc)
                .contentShape(Rectangle())
                .onTapGesture {
                    expandTimeArc.toggle()
                }
                .containerRelativeFrame(.horizontal) { width, _ in
                    width * 0.4 - (80)
                }
                InteractiveSwiftUIView(progress: coordinator.startingDurationForSlider) { factor in
                    coordinator.sliderFractionToTimeDuration(fraction: factor)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .transition(.popIn.animation(.easeInOut(duration: 0.1)))
            }
            
        }
    }
    
    
    // MARK: - LaunchControlTimeView
    
    struct LaunchControlTimeView: View {
        
        let duration: TimeInterval
        let durationString: String
        
        var body: some View {
            Text(durationString)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.invertedForegroundPrimary)
                .contentTransition(.numericText(value: duration))
                .animation(.easeInOut, value: duration)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(Color.invertedBackgroundPrimary, in: .capsule)
        }
    }
    
    
    // MARK: - PomodoroLaunchControlTimeView
    
    struct PomodoroLaunchControlTimeView: View {
        
        let durationDescriptionString: String
        
        var body: some View {
            Text(durationDescriptionString)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(Color.invertedForegroundPrimary)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .background(Color.invertedBackgroundPrimary, in: .capsule)
        }
        
    }
}

#Preview {
    @Previewable @State var coordinator: FocusSessionCoordinator = .init(alarmCoordinator: nil, liveActivityCoordinator: nil, appShieldCoordinator: nil)
    FocusTimerLaunchControl(coordinator: coordinator) {
        print("Presenting")
    } presentBlockAppsSheet: {
        print("Presenting App block")        
    }
    .padding(.horizontal, 32)
    .fixedSize(horizontal: false, vertical: true)
}

