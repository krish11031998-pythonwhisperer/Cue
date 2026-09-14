//
//  FocusSessionKind.swift
//  Model
//
//  Created by Krishna Venkatramani on 24/08/2026.
//

import Foundation

public enum FocusSessionKind: Int32, Codable, Sendable {
    case classic = 0
    case pomodoro = 1
    
    public var displayName: String {
        switch self {
        case .classic:
            return "Classic"
        case .pomodoro:
            return "Pomodoro"
        }
    }
}
