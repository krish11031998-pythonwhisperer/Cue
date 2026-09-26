//
//  Font.swift
//  Cue
//
//  Created by Krishna Venkatramani on 05/04/2026.
//

import Foundation
import UIKit
import SwiftUI

enum Bitcount {
    case medium
    case regular
    
    var fontName: String {
        let prefix = "BitcountSingle"
        switch self {
        case .medium:
            return "\(prefix)-Medium"
        case .regular:
            return "\(prefix)-Regular"
        }
    }
    
    func customUIFontBuilder(style: UIFont.TextStyle) -> UIFont {
        let metrics = UIFontMetrics(forTextStyle: style)
        let pointSize = UIFont.preferredFont(forTextStyle: style,
                                             compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)).pointSize
        let font = UIFont(name: self.fontName, size: pointSize) ?? .systemFont(ofSize: pointSize, weight: .medium)
        return metrics.scaledFont(for: font)
    }
    
    func customFontBuilder(style: UIFont.TextStyle) -> Font {
        return Font(self.customUIFontBuilder(style: style))
    }
}

extension Font {
    static func bitcountMedium(style: UIFont.TextStyle) -> Font {
        return Bitcount.medium.customFontBuilder(style: style)
    }
    
    static func bitcountRegular(style: UIFont.TextStyle) -> Font {
        return Bitcount.regular.customFontBuilder(style: style)
    }
}

extension UIFont {
    static func bitcountMedium(style: UIFont.TextStyle) -> UIFont {
        return Bitcount.medium.customUIFontBuilder(style: style)
    }
    
    static func bitcountRegular(style: UIFont.TextStyle) -> UIFont {
        return Bitcount.regular.customUIFontBuilder(style: style)
    }
}
