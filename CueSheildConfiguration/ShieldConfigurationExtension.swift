//
//  ShieldConfigurationExtension.swift
//  CueSheildConfiguration
//
//  Created by Krishna Venkatramani on 11/08/2026.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit

extension ShieldConfiguration {
    static func defaultConfiguration(appName: String) -> ShieldConfiguration {
        .init(backgroundBlurStyle: .systemMaterialDark,
              backgroundColor: .black,
              icon: .init(systemName: "hourglass"),
              title: .init(text: "Stay Focused", color: .white),
              subtitle: .init(text: "You are currently in a focus session and have blocked this \(appName)", color: .secondaryLabel),
              primaryButtonLabel: .init(text: "Close", color: .black),
              primaryButtonBackgroundColor: .white,
              secondaryButtonLabel: nil)
    }
}

// Override the functions below to customize the shields used in various situations.
// The system provides a default appearance for any methods that your subclass doesn't override.
// Make sure that your class name matches the NSExtensionPrincipalClass in your Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        configureShield(application.localizedDisplayName ?? "this app")
    }

    override func configuration(shielding application: Application, in category: ActivityCategory) -> ShieldConfiguration {
        configureShield(application.localizedDisplayName ?? category.localizedDisplayName ?? "this app")
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        configureShield(webDomain.domain ?? "this website")
    }

    override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory) -> ShieldConfiguration {
        configureShield(webDomain.domain ?? category.localizedDisplayName ?? "this website")
    }
    
    private nonisolated func configureShield(_ applicationName: String) -> ShieldConfiguration {
        
        guard let cueShieldConfiguration = CueAppBlockManager.retrieveShieldConfiguration() else {
            return .defaultConfiguration(appName: applicationName)
        }
        
        return .shieldConfiguration(with: cueShieldConfiguration, appName: applicationName)
    }
}
