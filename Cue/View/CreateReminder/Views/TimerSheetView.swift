//
//  TimerSheetView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 18/01/2026.
//

import SwiftUI
import VanorUI

struct TimerSheetView: View {
    
    enum Bound {
        case day
        case hour
        
        var step: TimeInterval {
            switch self {
            case .day:
                return 24 * 60 * 60
            case .hour:
                return 60
            }
        }
    }
    
    @Binding var timeDuration: TimeInterval
    private let title: String
    private let bound: Bound
    private let startingProgress: CGFloat
    
    init(timeDuration: Binding<TimeInterval>, title: String, bound: Bound) {
        self._timeDuration = timeDuration
        self.title = title
        self.bound = bound
        self.startingProgress = timeDuration.wrappedValue / bound.step
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Label("Snooze Duration", systemSymbol: .zzz)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Group {
                switch bound {
                case .day:
                    Text(String.formatttedTimeIntervalToDate(timeDuration))
                case .hour:
                    Text(String.formattedTimelineInterval(timeDuration))
                }
            }
            .font(.title)
            .fontWeight(.semibold)
            .contentTransition(.numericText(value: timeDuration))
            .animation(.easeInOut, value: timeDuration)
            .padding(.bottom, 24)
            
            InteractiveSwiftUIView(progress: startingProgress) { progress in
                computeTime(progress: progress)
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 32)
    }
    
    
    // MARK: - Compute Time
    
    private func computeTime(progress: CGFloat) {
        let timeInDay: TimeInterval = bound.step
        let time = progress * timeInDay
        self.timeDuration = time.rounded(.up)
    }
    
    private var durationString: String {
        var result: String = ""
        let formatter = MeasurementFormatter()
        formatter.unitOptions = .providedUnit

        let hours: TimeInterval = TimeInterval(timeDuration / 60).rounded(.down)
        if hours > 0 {
            let hourMeasurement = Measurement(value: hours, unit: UnitDuration.hours)
            result += formatter.string(from: hourMeasurement) + " "
        }
        
        let minutes = timeDuration.truncatingRemainder(dividingBy: 60)
        let measurement = Measurement(value: minutes, unit: UnitDuration.minutes)
        result += formatter.string(from: measurement)
        
        return result
    }
}


#Preview {
    @Previewable @State var time: TimeInterval = 15
    @Previewable @State var timeDay: TimeInterval = Date.now.timeIntervalSince(Date.now.startOfDay)
    TimerSheetView(timeDuration: $timeDay, title: "Day", bound: .day)
    TimerSheetView(timeDuration: $time, title: "Snoozing Duaration", bound: .hour)
}
