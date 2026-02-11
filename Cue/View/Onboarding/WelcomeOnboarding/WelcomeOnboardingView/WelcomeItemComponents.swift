//
//  WelcomeItemComponents.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/02/2026.
//

import VanorUI
import SwiftUI

public enum WelcomeItemComponents: CaseIterable, Identifiable {
    case useAI
    case alarms
    case habits
    case focus
    
    public var id: String {
        switch self {
        case .useAI:
            "useAI"
        case .alarms:
            "alarms"
        case .habits:
            "habits"
        case .focus:
            "focus"
        }
    }
    
    public var title: String {
        switch self {
        case .useAI:
            return "Use cue:ai to create your reminders"
        case .alarms:
            return "Notifications + Alarms = No Missing Reminders"
        case .habits:
            return "Track your habits"
        case .focus:
            return "Focus"
        }
    }
    
    public var color: LCHColor {
        switch self {
        case .useAI:
            return Color.proRed
        case .alarms:
            return Color.proBlue
        case .habits:
            return Color.proYellow
        case .focus:
            return Color.proIris
        }
    }
    
    public var icon: Icon {
        switch self {
        case .useAI:
            return .symbol(.appleIntelligence)
        case .alarms:
            return .symbol(.alarmWavesLeftAndRightFill)
        case .habits:
            return .symbol(.target)
        case .focus:
            return .symbol(.circleDashed)
        }
    }
    
    var rotationAngle: CGFloat {
        switch self {
        case .useAI:
            -1.5
        case .alarms:
            -3.5
        case .habits:
            0.15
        case .focus:
            -2.5
        @unknown default:
            fatalError()
        }
    }
    
    static var cases: [WelcomeItemComponents] {
        [.useAI, .alarms, .focus]
    }
}
