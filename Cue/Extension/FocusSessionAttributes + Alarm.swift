//
//  FocusSessionAttributes + Alarm.swift
//  Cue
//
//  Created by Krishna Venkatramani on 14/09/2026.
//

import Model
import VanorUI

extension FocusSessionLiveActivityAttributes.FocusSessionType {
    
    var focusSessionKind: FocusSessionKind {
        switch self {
        case .classic:
            return .classic
        case .pomodoro:
            return .pomodoro
        }
    }
}

extension CueFocusAlarmAttributes {
    
    /// Bridges the session's on-screen identity into the `Model` spelling AlarmKit stores
    /// on the alarm. `Model` cannot see VanorUI, so `Icon` / `LCHColor` are flattened to
    /// `CueIcon` / a hex string here.
    ///
    /// `sessionType` is nil until the session actually starts; a session being scheduled an
    /// alarm is a Classic one unless told otherwise.
    init(_ sessionAttributes: FocusSessionAttributes) {
        self.init(title: sessionAttributes.name,
                  icon: .from(sessionAttributes.icon),
                  colorHex: sessionAttributes.color.baseColor.getHexString(),
                  sessionKind: sessionAttributes.sessionType?.focusSessionKind ?? .classic,
                  numberOfTasks: sessionAttributes.numberOfTasks)
    }
}
