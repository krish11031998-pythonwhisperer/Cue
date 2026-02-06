//
//  CueIcon + Icon.swift
//  Cue
//
//  Created by Krishna Venkatramani on 05/02/2026.
//

import VanorUI
import Model

extension Icon {
    init?(_ cueIcon: CueIcon) {
        if let emoji = cueIcon.emoji {
            self = .emoji(.init(emoji))
        } else if let symbol = cueIcon.symbol {
            self = .symbol(.init(rawValue: symbol))
        } else {
            return nil
        }
    }
}


extension CueIcon {
    static func from(_ icon: Icon) -> CueIcon {
        switch icon {
        case .emoji(let emoji):
            return .init(symbol: nil, emoji: emoji.char)
        case .symbol(let value):
            return .init(symbol: value.rawValue, emoji: nil)
        }
    }
}
