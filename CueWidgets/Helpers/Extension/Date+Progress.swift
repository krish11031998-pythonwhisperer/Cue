//
//  Date+Progress.swift
//  Cue
//
//  Created by Krishna Venkatramani on 08/08/2026.
//

import Foundation

extension Date {
    
    func progress(start startDate: Date, end endDate: Date) -> CGFloat {
        let timeIntervalSinceStart = endDate.timeIntervalSince(startDate)
        let timeIntervalNowSinceStart = self.timeIntervalSince(startDate)
        
        return CGFloat(timeIntervalNowSinceStart/timeIntervalSinceStart)
    }
    
}
