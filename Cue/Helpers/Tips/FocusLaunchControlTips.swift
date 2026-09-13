//
//  FocusLaunchControlTips.swift
//  Cue
//
//  Created by Krishna Venkatramani on 13/09/2026.
//

import SwiftUI
import VanorUI
import TipKit

/// Launch-control tips advance their ordered `TipGroup` through an explicit button rather than
/// the popover's ✕ — see `NextTipViewStyle`, which is what removes that ✕.
protocol LaunchControlTip: Tip {
    var nextTitle: String { get }
}

extension LaunchControlTip {
    var nextTitle: String { "Next" }
    
    var actions: [Action] {
        [Action(id: "next", title: nextTitle) { invalidate(reason: .actionPerformed) }]
    }
}

struct SessionDurationTip: LaunchControlTip {
    var title: Text { Text("Session length") }
    var message: Text? { Text("Tap to scrub, ± to nudge.") }
    var image: Image? { Image(systemSymbol: .clock) }
}

struct BlockAppsTip: LaunchControlTip {
    var title: Text { Text("Block apps") }
    var message: Text? { Text("Shut out apps and sites while you focus.") }
    var image: Image? { Image(systemSymbol: .lockAppDashed) }
}

struct FocusTimerTypeTip: LaunchControlTip {
    var title: Text { Text("Classic or Pomodoro") }
    var message: Text? { Text("One stretch, or blocks with breaks.") }
    var image: Image? { Image(systemSymbol: .timer) }
}

struct SessionAlarmTip: LaunchControlTip {
    var nextTitle: String { "Got it" }
    var title: Text { Text("Alarm") }
    var message: Text? { Text("Ring when the session ends.") }
    var image: Image? { Image(systemSymbol: .alarmWavesLeftAndRight) }
}
