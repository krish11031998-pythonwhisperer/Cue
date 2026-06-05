//
//  FocusTimeViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 30/05/2026.
//

import Model
import Foundation


@Observable
class FocusTimeViewModel {
    
    private static let secondsInAMinute: TimeInterval = 60
    
    private enum Constants {
        static let secondsInAMinute: TimeInterval = 60
    }
    
    var calendarDay: CalendarDay? = nil
    var timeDuration: TimeInterval = 30 * Constants.secondsInAMinute
    
    @concurrent
    func fetchRemindersForToday() async {
        do {
            let calendarDay = try await CalendarManager.shared.setupCalendarDay(for: .now)
            await MainActor.run {
                self.calendarDay = calendarDay
            }
        } catch {
            print("(ERROR) error: ", error.localizedDescription)
        }
    }
}
