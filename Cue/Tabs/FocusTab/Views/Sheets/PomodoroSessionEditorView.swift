//
//  PomodoroSessionEditorView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 21/06/2026.
//

import VanorUI
import SwiftUI
import Model

struct PomodoroButtonStyle: ButtonStyle {
    
    let isSelected: Bool
    let theme: LCHColor
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.init(top: 8, leading: 10, bottom: 8, trailing: 10))
            .foregroundStyle(isSelected ? Color.invertedForegroundPrimary : Color.foregroundPrimary)
            .containerShape(Rectangle())
            .glassEffect(.regular.tint(isSelected ? theme.baseColor : theme.surfacePrimary).interactive(true), in: .capsule)
    }
}


struct PomodoroSessionEditorView: View {
    
    enum Options: CaseIterable, Identifiable {
        case sessionDuration
        case breakDuration
        case numberOfSessions
        
        var buttonTitle: String {
            switch self {
            case .sessionDuration:
                return "Session Duration"
            case .breakDuration:
                return "Break Duration"
            case .numberOfSessions:
                return "Sessions"
            }
        }
        
        var id: String { buttonTitle }
    }
    
    @Environment(\.theme) var theme
    @Environment(\.dismiss) var dismiss
    
    private static let minuteInTimeInterval: TimeInterval = 60
    private static let sessionDurationLowerBound: TimeInterval = 5 * Self.minuteInTimeInterval
    private static let sessionDurationUpperBound: TimeInterval = 46 * Self.minuteInTimeInterval
    private static let breakDurationLowerBound: TimeInterval = 5 * Self.minuteInTimeInterval
    private static let breakDurationUpperBound: TimeInterval = 21 * Self.minuteInTimeInterval
    private static let sessionCountLowerBound: Int = 1
    private static let sessionCountUpperBound: Int = 11
    
    @Bindable var coordinator: FocusSessionCoordinator
    @State private var selectedButton: Options = .sessionDuration
    
    private var sessionDuration: TimeInterval { coordinator.timerDuration }
    private var breakDuration: TimeInterval { coordinator.breakDuration }
    private var sessionCount: Int { coordinator.pomodoroSessionCount }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                HStack(alignment: .center, spacing: 4) {
                    Text("Pomodoro session")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Button(role: .confirm, action: {
                        dismiss()
                    })
                    .fontWeight(.semibold)
                    .tint(theme.baseColor)
                    .buttonStyle(.glassProminent)
                }
                
                OverFlowingHorizontalLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                    ForEach(Options.allCases, id: \.self) { option in
                        Button {
                            selectedButton = option
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(option.buttonTitle)
                                    .font(.system(size: 10, weight: .medium, design: .default))
                                switch option {
                                case .sessionDuration:
                                    Text(sessionDuration.timerDurationString)
                                        .font(.footnote.weight(.semibold))
                                case .breakDuration:
                                    Text(breakDuration.timerDurationString)
                                        .font(.footnote.weight(.semibold))
                                case .numberOfSessions:
                                    Text("\(sessionCount)")
                                        .font(.footnote.weight(.semibold))
                                }
                            }
                        }
                        .buttonStyle(PomodoroButtonStyle(isSelected: selectedButton == option, theme: theme))
                    }
                }
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .center)
            
            component
                .animation(.easeInOut) { content in
                    content
                        .transition(.blurReplace)
                }
        }
        .padding(.top, 16)
        .frame(maxHeight: .infinity, alignment: .center)
    }
    
    @ViewBuilder
    private var component: some View {
        switch selectedButton {
        case .sessionDuration:
            PomodoroEditorComponent(range: Self.sessionDurationLowerBound..<Self.sessionDurationUpperBound, stride: Self.minuteInTimeInterval, value: $coordinator.timerDuration)
        case .breakDuration:
            PomodoroEditorComponent(range: Self.breakDurationLowerBound..<Self.breakDurationUpperBound, stride: Self.minuteInTimeInterval, value: $coordinator.breakDuration)
        case .numberOfSessions:
            PomodoroEditorComponent(range: Self.sessionCountLowerBound..<Self.sessionCountUpperBound, stride: 1, value: $coordinator.pomodoroSessionCount, type: .even)
        }
    }
    
    
    // MARK: - EditorComponent
    
    struct PomodoroEditorComponent<Element: Comparable & Strideable & Numeric & Hashable>: View {
        
        let range: Range<Element>
        let stride: Element.Stride
        @Binding var value: Element
        let type: SegmentedSliderViewType
        
        init(range: Range<Element>, stride: Element.Stride, value: Binding<Element>, type: SegmentedSliderViewType = .uneven(step: 5)) {
            self.range = range
            self.stride = stride
            self._value = value
            self.type = type
        }
        
        var title: String {
            switch value {
            case let timeInterval as TimeInterval:
                return timeInterval.timerDurationString
            default:
                return "\(value)"
            }
        }
        
        var body: some View {
            VStack(alignment: .center, spacing: 0) {
                Group {
                    switch value {
                    case let timeInterval as TimeInterval:
                        Text(timeInterval.timerDurationString)
                            .contentTransition(.numericText(value: timeInterval))
                            .animation(.easeOut, value: timeInterval)
                    default:
                        Text(title)
                    }
                }
                .font(.largeTitle.weight(.semibold))
                .foregroundStyle(Color.primary)
                .padding(.bottom, 12)

                TimerSliderView(range: range, stride: stride, value: $value, type: type)
            }
        }
        
    }
}

fileprivate struct TestView: View {
    
    @State private var presentSheet: Bool = false
    @State private var coordinator: FocusSessionCoordinator = .init(alarmCoordinator: nil, liveActivityCoordinator: nil, appShieldCoordinator: nil)
    
    var body: some View {
        Button {
            presentSheet = true
        } label: {
            Text("Present Sheet")
                .font(.headline)
                .padding(.all, 12)
        }
        .tint(.accentColor)
        .glassEffect(.regular, in: .capsule)
        .sheet(isPresented: $presentSheet) {
            PomodoroSessionEditorView(coordinator: coordinator)
                .fittedPresentationDetent()
        }

    }
    
}

#Preview {
    PomodoroSessionEditorView(coordinator: .init(alarmCoordinator: nil, liveActivityCoordinator: nil, appShieldCoordinator: nil))
//        .environment(FocusSessionCoordinator(alarmCoordinator: CueAlarmManager()))
}

#Preview {
    TestView()
}
