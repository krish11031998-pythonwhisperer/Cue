//
//  TimerHeaderView.swift
//  Kyu
//
//  Created by Krishna Venkatramani on 12/02/2026.
//

import Foundation
import SwiftUI
import Model
import VanorUI

struct TimerHeaderView: View {
    
    let reminder: ReminderModel?
    let duration: TimeInterval
    
    var durationTimeSting: String {
        let startTime = Date.now
        let endTime = startTime.addingTimeInterval(duration)
        
        let startTimeString = startTime.timeBuilder()
        let endTimeString = endTime.timeBuilder()
        
        return "\(startTimeString) → \(endTimeString)"
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Group {
                if let reminder {
                    Text(reminder.title)
                } else {
                    Text("Focus")
                }
            }
            .font(.largeTitle)
            .fontWeight(.semibold)
            .lineLimit(2)
            .minimumScaleFactor(0.5)
            .multilineTextAlignment(.center)
            
            Text(durationTimeSting)
                .font(.headline)
        }
    }
}
