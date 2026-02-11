//
//  CueItProFeatures.swift
//  Cue
//
//  Created by Krishna Venkatramani on 11/02/2026.
//

import VanorUI
import SwiftUI

enum CueItProFeatures: Int, CaseIterable, Identifiable {
    case focusTimer
    case tags
    case unlimitedReminders
    
    var symbol: SFSymbol {
        switch self {
        case .focusTimer:
            return .stopwatch
        case .tags:
            return .tagFill
        case .unlimitedReminders:
            return .bellFill
        }
    }
    
    var title: String {
        switch self {
        case .focusTimer:
            return "Focus Timer"
        case .tags:
            return "Tags"
        case .unlimitedReminders:
            return "Flexible Reminders"
        }
    }
    
    var message: String {
        switch self {
        case .focusTimer:
            return "Finish tasks without distractions"
        case .tags:
            return "Build routines and stay consistent"
        case .unlimitedReminders:
            return "Never miss a task again"
        }
    }
    
    var theme: LCHColor {
        let theme: LCHColor
        switch self {
        case .focusTimer:
            theme = Color.proRed
        case .tags:
            theme = Color.proBlue
        case .unlimitedReminders:
            theme = Color.proCyan
        }
        return theme
    }
    
    var tint: Color {
        theme.baseColor
    }
    
    var id: String {
        title
    }
}
