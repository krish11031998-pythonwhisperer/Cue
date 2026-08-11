//
//  FocusAppShieldCoordinator.swift
//  Cue
//
//  Created by Krishna Venkatramani on 11/08/2026.
//

import Foundation
import ManagedSettingsUI
import FamilyControls

@MainActor
protocol FocusAppShieldCoordinator {
    func applyRestrictions(_ selection: FamilyActivitySelection)
    func saveShieldConfiguration(_ shieldConfiguration: CueShieldConfigurationModel)
    func removeRestrictions()
}
