//
//  TimerSheetView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 18/01/2026.
//

import SwiftUI
import VanorUI

struct TimerSheetView<Element: Comparable & Strideable & Numeric & Hashable>: View {
    
    enum ControlType {
        case snoozeDuration
        case remindMe
        case focusTimerDuration
        case focusTimerBreakDuration
        case focusTimerBreakCount
        
        var range: Range<Element> {
            switch self {
            case .snoozeDuration, .focusTimerBreakDuration:
                return (5 * 60)..<(61 * 60)
            case .remindMe, .focusTimerDuration:
                return (5 * 60)..<(24 * 60 * 60 + 60)
            case .focusTimerBreakCount:
                return 1..<11
            }
        }
        
        var stride: Element.Stride {
            switch self {
            case .snoozeDuration, .remindMe:
                return 1 * 60
            case .focusTimerDuration, .focusTimerBreakDuration:
                return 5 * 60
            case .focusTimerBreakCount:
                return 1
            }
        }
        
        var type: SegmentedSliderViewType {
            switch self {
            case .snoozeDuration, .remindMe, .focusTimerDuration, .focusTimerBreakDuration:
                return .uneven(step: 5)
            case .focusTimerBreakCount:
                return .even
            }
        }
        
        var title: String {
            switch self {
            case .snoozeDuration:
                return "Snooze Duration"
            case .remindMe:
                return "Remind Me Before"
            case .focusTimerDuration:
                return "Session Duration"
            case .focusTimerBreakDuration:
                return "Break Session Duration"
            case .focusTimerBreakCount:
                return "Sessions"
            }
        }
        
        var symbol: SFSymbol {
            switch self {
            case .snoozeDuration:
                return .zzz
            case .remindMe:
                return .clockArrowTriangleheadCounterclockwiseRotate90
            case .focusTimerDuration:
                return .timer
            case .focusTimerBreakDuration:
                return .clockArrowTriangleheadClockwiseRotate90PathDotted
            case .focusTimerBreakCount:
                return .number
            }
        }
    }
    
    @Binding var timeDuration: Element
    let controlType: ControlType
    
    init(timeDuration: Binding<Element>, controlType: ControlType) {
        self._timeDuration = timeDuration
        self.controlType = controlType
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Label(controlType.title, systemSymbol: controlType.symbol)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Group{
                switch timeDuration {
                case let interval as TimeInterval:
                    Text(String.formattedTimelineInterval(interval))
                        .contentTransition(.numericText(value: Double(interval)))
                        .animation(.easeInOut, value: timeDuration)
                case let count as Int:
                    Text("\(count)")
                        .contentTransition(.numericText(value: Double(count)))
                        .animation(.easeInOut, value: count)
                default:
                    Text("\(timeDuration)")
                }
            }
            .font(.title)
            .fontWeight(.semibold)
            .padding(.bottom, 24)

            TimerSliderView(range: controlType.range, stride: controlType.stride, value: $timeDuration, type: controlType.type)
        }
        .padding(.top, 32)
        .padding(.bottom, 12)
    }
}


#Preview {
    @Previewable @State var time: TimeInterval = 15
    @Previewable @State var timeDay: TimeInterval = Date.now.timeIntervalSince(Date.now.startOfDay)
    TimerSheetView(timeDuration: $timeDay, controlType: .snoozeDuration)
    TimerSheetView(timeDuration: $time, controlType: .remindMe)
}
