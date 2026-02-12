//
//  Color+HJex.swift
//  Model
//
//  Created by Krishna Venkatramani on 12/02/2026.
//

import UIKit

extension UIColor {
    convenience init?(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")

        // Support short forms like FFF or FFFFFF if you want (optional)
        if hexString.count == 3 {
            hexString = hexString.map { "\($0)\($0)" }.joined()
        }

        var value: UInt64 = 0
        guard Scanner(string: hexString).scanHexInt64(&value) else { return nil }

        let a, r, g, b: UInt64

        switch hexString.count {
        case 6: // RRGGBB
            (a, r, g, b) = (255, value >> 16, value >> 8 & 0xFF, value & 0xFF)

        case 8: // AARRGGBB
            (a, r, g, b) = (value >> 24, value >> 16 & 0xFF, value >> 8 & 0xFF, value & 0xFF)

        default:
            return nil
        }

        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
    
    func toHex() -> String? {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        guard self.getRed(&r, green: &g, blue: &b, alpha: &a) else {
            return nil // not convertible (like pattern colors)
        }

        return String(
            format: "#%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )        
    }
}
