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
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.init(top: 6, leading: 14, bottom: 6, trailing: 14))
            .foregroundStyle(isSelected ? Color.invertedForegroundPrimary : Color.foregroundPrimary)
            .background(isSelected ? Color.invertedBackgroundPrimary : Color.surfacePrimary, in: .capsule)
            .scaleEffect(.init(squared: configuration.isPressed ? 0.95 : 1), anchor: .center)
            .opacity(configuration.isPressed ? 0.9 : 1)
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
    
    private static let minuteInTimeInterval: TimeInterval = 60
    private static let sessionDurationLowerBound: TimeInterval = 5 * Self.minuteInTimeInterval
    private static let sessionDurationUpperBound: TimeInterval = 46 * Self.minuteInTimeInterval
    private static let breakDurationLowerBound: TimeInterval = 5 * Self.minuteInTimeInterval
    private static let breakDurationUpperBound: TimeInterval = 21 * Self.minuteInTimeInterval
    private static let sessionCountLowerBound: Int = 1
    private static let sessionCountUpperBound: Int = 11
    
    @State private var selectedButton: Options = .sessionDuration
    @State private var sessionDuration: TimeInterval = 5 * Self.minuteInTimeInterval
    @State private var breakDuration: TimeInterval = 5 * Self.minuteInTimeInterval
    @State private var sessionCount: Int = 4
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 8) {
                Text("Edit your Pomodoro session")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(role: .confirm, action: {
                    // Confirm
                })
                .fontWeight(.semibold)
                .tint(Color.proOrange.baseColor)
                .buttonStyle(.glassProminent)
            }
            .padding(.horizontal, 20)
            
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
                    .buttonStyle(PomodoroButtonStyle(isSelected: selectedButton == option))
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .center)
            
            component
        }
        .padding(.top, 16)
        .frame(maxHeight: .infinity, alignment: .center)
//        .safeAreaPadding(.bottom, 32)
    }
    
    @ViewBuilder
    private var component: some View {
        switch selectedButton {
        case .sessionDuration:
            PomodoroEditorComponent(range: Self.sessionDurationLowerBound..<Self.sessionDurationUpperBound, stride: Self.minuteInTimeInterval, value: $sessionDuration)
        case .breakDuration:
            PomodoroEditorComponent(range: Self.breakDurationLowerBound..<Self.breakDurationUpperBound, stride: Self.minuteInTimeInterval, value: $breakDuration)
        case .numberOfSessions:
            PomodoroEditorComponent(range: Self.sessionCountLowerBound..<Self.sessionCountUpperBound, stride: 1, value: $sessionCount, type: .even)
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
            PomodoroSessionEditorView()
                .fittedPresentationDetent()
        }

    }
    
}

#Preview {
    PomodoroSessionEditorView()
//        .environment(FocusTimerLaunchControlCoordinator(alarmCoordinator: CueAlarmManager()))
}

#Preview {
    TestView()
}
