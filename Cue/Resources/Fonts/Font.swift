//
//  Font.swift
//  Cue
//
//  Created by Krishna Venkatramani on 05/04/2026.
//

import Foundation
import UIKit
import SwiftUI

extension Font {
    
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
    }
    
    static func bitcountMedium(style: UIFont.TextStyle) -> Font {
        return Self.customFontBuilder(name: Bitcount.medium.fontName, style: style)
    }
    
    static func bitcountRegular(style: UIFont.TextStyle) -> Font {
        return Self.customFontBuilder(name: Bitcount.regular.fontName, style: style)
    }
    
    private static func customFontBuilder(name: String, style: UIFont.TextStyle) -> Font {
        let metrics = UIFontMetrics(forTextStyle: style)
        let pointSize = UIFont.preferredFont(forTextStyle: style,
                                             compatibleWith: UITraitCollection(preferredContentSizeCategory: .large)).pointSize
        let font = UIFont(name: name, size: pointSize) ?? .systemFont(ofSize: pointSize, weight: .medium)
        return Font(metrics.scaledFont(for: font))
    }
    
}
