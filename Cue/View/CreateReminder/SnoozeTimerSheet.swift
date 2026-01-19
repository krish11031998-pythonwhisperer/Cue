//
//  SnoozeTimerSheet.swift
//  Cue
//
//  Created by Krishna Venkatramani on 18/01/2026.
//

import SwiftUI
import VanorUI
import KKit


struct SnoozeTimerSheet: View {
    
    @Binding var timeDuration: TimeInterval
    private let startingProgress: CGFloat
    
    init(timeDuration: Binding<TimeInterval>) {
        self._timeDuration = timeDuration
        self.startingProgress = timeDuration.wrappedValue / (24 * 60)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Text("Snooze Duration")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Text(String.formattedTimelineInterval(timeDuration))
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
        let timeInDay: TimeInterval = 24 * 60
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
    SnoozeTimerSheet(timeDuration: $time)
}
