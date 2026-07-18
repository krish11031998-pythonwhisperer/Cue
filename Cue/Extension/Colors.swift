//
//  Colors.swift
//  Cue
//
//  Created by Krishna Venkatramani on 24/07/2026.
//

import SwiftUI
import Model

extension Array where Self.Element == Color {
    static let defaultColors: [Color] = [.honey, .sand, .peach , .rose, .orchid, .lavender, .perwinkle, .sky, .aqua, .mint, .leaf, .lemon]
}

extension Color {
    var assetName: String {
        switch self {
        case .sky:
            return "sky"
        case .aqua:
            return "aqua"
        case .leaf:
            return "leaf"
        case .lemon:
            return "lemon"
        case .honey:
            return "honey"
        case .sand:
            return "sand"
        case .perwinkle:
            return "perwinkle"
        case .orchid:
            return "orchid"
        case .peach:
            return "peach"
        case .rose:
            return "rose"
        case .lavender:
            return "lavender"
        case .mint:
            return "mint"
        default:
            return "N/A"
        }
    }
}

extension ReminderModel {
    var color: Color {
        .init(colorName)
    }
}
