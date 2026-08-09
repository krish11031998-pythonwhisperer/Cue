//
//  FocusSessionState.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/08/2026.
//

import Foundation
import VanorUI

enum FocusSessionState {
    case idle
    case start
    case resume
    case pause
    case reset
    
    public static let stop: String = "stop"
    
    public mutating func toggle() {
        switch self {
        case .idle:
            self = .start
        case .start, .resume:
            self = .pause
        case .pause:
            self = .resume
        case .reset:
            break
        }
    }
}

extension FocusSessionState {
    var uiState: FocusSessionUIState {
        switch self {
        case .idle:
            return .idle
        case .pause:
            return .pause
        case .reset:
            return .reset
        case .resume:
            return .resume
        case .start:
            return .start
        }
    }
}
