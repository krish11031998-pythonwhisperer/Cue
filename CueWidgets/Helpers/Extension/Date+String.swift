//
//  Date+String.swift
//  Cue
//
//  Created by Krishna Venkatramani on 08/08/2026.
//

import Foundation

extension Date {
    func timeBuilder() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm a"
        formatter.amSymbol = "AM"
        formatter.pmSymbol = "PM"
        return formatter.string(from: self)
    }
    
    func measurementString(startDate: Date, endDate: Date, restTime: TimeInterval) -> String {

        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.unitStyle = .short
        measurementFormatter.unitOptions = .providedUnit
        measurementFormatter.numberFormatter.maximumFractionDigits = 0

        let totalDuration = endDate.timeIntervalSince(startDate)
        let elapsedDuration = self.timeIntervalSince(startDate)

        let timeLeft = totalDuration - elapsedDuration - restTime

        let remainingTime = max(0, (timeLeft).rounded(.toNearestOrAwayFromZero))
        let mins = (remainingTime/60).rounded(.down)

        if mins > 60 {
            let hours = Int(mins / 60)
            let minutesRemainder = Int(mins.truncatingRemainder(dividingBy: 60))
            return "\(hours)h \(minutesRemainder)m"
        }

        let seconds = remainingTime.truncatingRemainder(dividingBy: 60)
        let secondsMeasurement = Measurement(value: seconds, unit: UnitDuration.seconds)

        if mins > 0 {
            let minutesMeasurement = Measurement(value: mins, unit: UnitDuration.minutes)
            return "\(measurementFormatter.string(from: minutesMeasurement)) \(measurementFormatter.string(from: secondsMeasurement))"
        } else {
            return measurementFormatter.string(from: secondsMeasurement)
        }
    }
}
