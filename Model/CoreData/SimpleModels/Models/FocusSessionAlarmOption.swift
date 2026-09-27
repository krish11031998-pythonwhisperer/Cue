//
//  FocusSessionAlarmOption.swift
//  Model
//
//  Created by Krishna Venkatramani on 24/08/2026.
//

import Foundation

public enum FocusSessionAlarmOption: Int32, Hashable, Sendable {
    case off = 0
    case endOfSession = 1
    case betweenSessions = 2
}
