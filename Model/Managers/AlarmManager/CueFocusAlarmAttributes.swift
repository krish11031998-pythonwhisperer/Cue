//
//  CueFocusAlarmAttributes.swift
//  Cue
//
//  Created by Krishna Venkatramani on 05/06/2026.
//

import AlarmKit
import Foundation

/// Metadata carried by a Focus Session alarm.
///
/// AlarmKit hands this back to the alarm's Live Activity when the alarm fires, and the
/// widget extension has no way of reaching the running `FocusSessionCoordinator` at that
/// point. So everything the alarm needs in order to look like the session it belongs to
/// has to be baked in here at scheduling time.
///
/// This mirrors `FocusSessionAttributes` (VanorUI), which `Model` cannot see - hence the
/// `CueIcon` / hex-string / `FocusSessionKind` spelling of the same values. The bridge
/// lives in `FocusSessionAttributes + Alarm.swift`.
public struct CueFocusAlarmAttributes: AlarmMetadata {
    
    /// Name of the session the alarm belongs to - "Focus", or the reminder's title.
    public let title: String
    /// The session's icon, so the alarm shows the same symbol / emoji as the session does.
    public let icon: CueIcon
    /// Hex of the session's theme colour (`LCHColor.baseColor`). The same colour is handed
    /// to AlarmKit as the alarm's `tintColor`; it is kept here so that any surface holding
    /// only the metadata can still theme itself like the session.
    public let colorHex: String
    /// Classic vs Pomodoro.
    public let sessionKind: FocusSessionKind
    /// Tasks attached to the session's reminder, `0` when the session has no reminder.
    public let numberOfTasks: Int
    
    public init(title: String,
                icon: CueIcon,
                colorHex: String,
                sessionKind: FocusSessionKind,
                numberOfTasks: Int) {
        self.title = title
        self.icon = icon
        self.colorHex = colorHex
        self.sessionKind = sessionKind
        self.numberOfTasks = numberOfTasks
    }
    
    /// "Pomodoro • 3 tasks" - the session's shape, for the line under the title.
    public var subtitle: String {
        var result = sessionKind.displayName
        if numberOfTasks > 0 {
            result += " • \(numberOfTasks) task\(numberOfTasks == 1 ? "" : "s")"
        }
        return result
    }
}
