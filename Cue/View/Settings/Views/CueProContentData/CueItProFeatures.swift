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
/// `allCases` order is the order both screens render, so the four core features lead and `tags`
/// closes. Keep `message` to a single short line — these render as footnotes under the title.
enum CueItProFeatures: Int, CaseIterable, Identifiable {
    case routines
    case focusSession
    case alarms
    case ai
    case tags
    
    var symbol: SFSymbol {
        switch self {
        case .routines:
            return .arrowTrianglehead2ClockwiseRotate90
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
        case .routines:
            return "Routines"
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
        case .routines:
            return "Recurring plans, broken into subtasks."
        case .focusSession:
            return "Focus timers that lock out distracting apps."
        case .alarms:
            return "Reminders that go off, not ones you swipe away."
        case .ai:
            return "Speak it once and plan your day."
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
        case .routines, .focusSession, .alarms, .tags:
            return nil
        }
    }
    
    var theme: LCHColor {
        let theme: LCHColor
        switch self {
        case .routines:
            theme = Color.proIndigo
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
