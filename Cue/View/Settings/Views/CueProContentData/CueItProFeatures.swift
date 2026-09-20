//
//  CueItProFeatures.swift
//  Cue
//
//  Created by Krishna Venkatramani on 11/02/2026.
//

import VanorUI
import SwiftUI

/// The pro features advertised on `CuePaywallView` and `ManageSubsriptionView`.
///
/// `allCases` order is the order both screens render, so the three core features lead and `tags`
/// closes. Keep `message` to a single short line — these render as footnotes under the title.
enum CueItProFeatures: Int, CaseIterable, Identifiable {
    case focusSession
    case alarms
    case ai
    case tags
    
    var symbol: SFSymbol {
        switch self {
        case .focusSession:
            return .stopwatch
        case .alarms:
            return .alarmWavesLeftAndRight
        case .ai:
            return .sparkles
        case .tags:
            return .tag
        }
    }
    
    var title: String {
        switch self {
        case .focusSession:
            return "Focus Sessions"
        case .alarms:
            return "Alarms"
        case .ai:
            return "cue:ai"
        case .tags:
            return "Tags"
        }
    }
    
    var message: String {
        switch self {
        case .focusSession:
            return "Unlimited sessions with Pomodoro timers and app blocking."
        case .alarms:
            return "Reminders that go off, not ones you swipe away."
        case .ai:
            return "Speak it, or let AI break a reminder into subtasks."
        case .tags:
            return "Group routines and filter your day by them."
        }
    }
    
    /// A caveat rendered under `message` wherever the feature is advertised. Only `ai` has one —
    /// it runs on the on-device model — so every other case is `nil` and renders nothing.
    var requirement: String? {
        switch self {
        case .ai:
            return "Only available on devices that support Apple Intelligence."
        case .focusSession, .alarms, .tags:
            return nil
        }
    }
    
    var theme: LCHColor {
        let theme: LCHColor
        switch self {
        case .focusSession:
            theme = Color.proRed
        case .alarms:
            theme = Color.proCyan
        case .ai:
            theme = Color.proBlue
        case .tags:
            theme = Color.proGreen
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
