//
//  CueShieldConfigurationModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 11/08/2026.
//

import Foundation
import ManagedSettings
import UIKit
import SwiftUI
import ManagedSettingsUI

fileprivate extension UIColor {
    static func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }

        if ((cString.count) != 6) {
            return UIColor.gray
        }

        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)

        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func colorToHex() -> String {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        // Extract color components
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        // Convert to hexadecimal
        let hexString = String(format: "#%02X%02X%02X",
                               Int(red * 255),
                               Int(green * 255),
                               Int(blue * 255))
        return hexString
    }
}

fileprivate extension Color {
    /// Converts the `Color` to a hexadecimal string representation.
    func getHexString() -> String {
        UIColor(self).colorToHex()
    }
}

extension ShieldActionResponse: @retroactive Codable {
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        self = .init(rawValue: rawValue) ?? .none
    }
}

struct CueShieldConfigurationModel: Codable, Sendable {
    
    struct Label: Codable {
        let title: String
        let colorHex: String
        
        init(title: String, color: Color) {
            self.title = title
            self.colorHex = color.getHexString()
        }
        
        var color: UIColor { .hexStringToUIColor(hex: colorHex) }
    }
    
    struct ButtonConfiguration: Codable {
        let title: String
        let foregroundHex: String
        let backgroundHex: String?
        let response: ShieldActionResponse
        
        var foreground: UIColor { .hexStringToUIColor(hex: foregroundHex) }
        var background: UIColor? {
            guard let backgroundHex else { return nil }
            return .hexStringToUIColor(hex: backgroundHex)
        }
        
        init(title: String, foreground: Color, background: Color?, response: ShieldActionResponse) {
            self.title = title
            self.foregroundHex = foreground.getHexString()
            self.backgroundHex = background?.getHexString()
            self.response = response
        }
    }
    
    struct FocusSession: Codable {
        let icon: UIImage
        let colorHex: String
        
        var color: UIColor { .hexStringToUIColor(hex: colorHex) }
        
        init(icon: UIImage, color: Color) {
            self.icon = icon
            self.colorHex = color.getHexString()
        }
        
        enum CodingKeys: CodingKey {
            case icon
            case colorHex
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            let imageData = icon.pngData()
            try container.encodeIfPresent(imageData, forKey: .icon)
            try container.encode(colorHex, forKey: .colorHex)
        }
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let imageData = try container.decodeIfPresent(Data.self, forKey: .icon),
               let image = UIImage(data: imageData) {
                self.icon = image
            } else {
                self.icon = .init(systemName: "questionmark")!
            }
            
            self.colorHex = try container.decode(String.self, forKey: .colorHex)
        }
    }
    
    let focusSession: FocusSession
    let title: Label
    let subtitle: Label
    let primaryButton: ButtonConfiguration
    let secondaryButton: ButtonConfiguration?
    
    static let placeholder: String = "{appName}"
}


extension CueShieldConfigurationModel.Label {
    func shieldLabel(replacementPlaceholder: String? = nil) -> ShieldConfiguration.Label {
        if let replacementPlaceholder {
            return .init(text: title.replacingOccurrences(of: CueShieldConfigurationModel.placeholder, with: replacementPlaceholder), color: color)
        } else {
            return .init(text: title, color: color)
        }
    }
}

extension CueShieldConfigurationModel.ButtonConfiguration {
    var buttonLabel: ShieldConfiguration.Label {
        .init(text: title, color: foreground)
    }
}

extension ShieldConfiguration {
    static func shieldConfiguration(with configurationModel: CueShieldConfigurationModel, appName: String) -> ShieldConfiguration {
        .init(backgroundBlurStyle: .systemMaterialDark,
              backgroundColor: configurationModel.focusSession.color,
              icon: configurationModel.focusSession.icon,
              title: configurationModel.title.shieldLabel(),
              subtitle: configurationModel.subtitle.shieldLabel(replacementPlaceholder: appName),
              primaryButtonLabel: configurationModel.primaryButton.buttonLabel,
              primaryButtonBackgroundColor: configurationModel.primaryButton.background,
              secondaryButtonLabel: configurationModel.secondaryButton?.buttonLabel)
    }
}
