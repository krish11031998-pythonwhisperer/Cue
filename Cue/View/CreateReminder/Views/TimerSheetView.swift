//
//  TimerSheetView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 18/01/2026.
//

import SwiftUI
import VanorUI

struct TimerSheetView: View {
    
    enum ControlType {
        case snoozeDuration
        case remindMe
        
        var range: Range<TimeInterval> {
            switch self {
            case .snoozeDuration:
                return (5 * 60)..<(61 * 60)
            case .remindMe:
                return (5 * 60)..<(24 * 60 * 60 + 60)
            }
        }
        
        var stride: TimeInterval {
            switch self {
            case .snoozeDuration:
                return 1 * 60
            case .remindMe:
                return 1 * 60
            }
        }
        
        var type: SegmentedSliderViewType {
            switch self {
            case .snoozeDuration:
                return .uneven(step: 5)
            case .remindMe:
                return .uneven(step: 5)
            }
        }
        
        var title: String {
            switch self {
            case .snoozeDuration:
                return "Snooze Duration"
            case .remindMe:
                return "Remind Me Before"
            }
        }
        
        var symbol: SFSymbol {
            switch self {
            case .snoozeDuration:
                return .zzz
            case .remindMe:
                return .clockArrowTriangleheadCounterclockwiseRotate90
            }
        }
    }
    
    @Binding var timeDuration: TimeInterval
    let controlType: ControlType
    
    init(timeDuration: Binding<TimeInterval>, controlType: ControlType) {
        self._timeDuration = timeDuration
        self.controlType = controlType
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Label(controlType.title, systemSymbol: controlType.symbol)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Text(String.formattedTimelineInterval(timeDuration))
                .font(.title)
                .fontWeight(.semibold)
                .contentTransition(.numericText(value: timeDuration))
                .animation(.easeInOut, value: timeDuration)
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
