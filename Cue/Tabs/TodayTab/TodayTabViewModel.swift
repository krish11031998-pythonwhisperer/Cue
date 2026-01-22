//
//  TodayTabViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 20/01/2026.
//

import Model
import KKit
import VanorUI
import ColorTokensKit
import SwiftUI
import SFSafeSymbols

@Observable
class TodayViewModel {
    var expandedReminder: Set<Reminder> = []
    
    func expandReminder(_ reminder: Reminder) {
        if expandedReminder.contains(reminder) {
            self.expandedReminder.remove(reminder)
        } else {
            self.expandedReminder.insert(reminder)
        }
    }
    
    func logReminder(_ reminder: Reminder) {
        print("(DEBUG) tapped on logging Reminder!")
    }
}
