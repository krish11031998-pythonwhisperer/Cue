//
//  SubscriptionManager + FocusSession.swift
//  Cue
//
//  Created by Krishna Venkatramani on 14/09/2026.
//

import Foundation
import Model

extension SubscriptionManager {
    
    /// Focus sessions a user without Pro is allowed to keep.
    ///
    /// One is a trial, not a tier: it is enough to build a session and live with it for a
    /// while, and going beyond it is what Pro is for.
    static let freeFocusSessionAllowance: Int = 1
    
    /// Whether the user may create one more focus session on top of `existingSessions`.
    func canCreateFocusSession(existingSessions: Int) -> Bool {
        store.isProUser || existingSessions < Self.freeFocusSessionAllowance
    }
    
    /// The sessions a user may actually see and start. Pro lifts the cap; everyone else
    /// keeps their allowance and the rest stay behind the paywall.
    func allowedFocusSessions(_ focusSessions: [FocusSessionModel]) -> [FocusSessionModel] {
        guard !store.isProUser else { return focusSessions }
        return Array(focusSessions.prefix(Self.freeFocusSessionAllowance))
    }
    
    /// Runs `action` while the user still has a focus session slot, and otherwise asks the
    /// nearest `paywallPresentation()` to show the paywall.
    ///
    /// The counterpart to `proUserAction` for a feature that is not gated outright but
    /// metered - creating a focus session is free until the allowance is used up.
    func focusSessionCreationAction(existingSessions: Int, _ action: @escaping () -> Void) {
        guard canCreateFocusSession(existingSessions: existingSessions) else {
            NotificationCenter.default.post(name: .presentPaywall, object: nil)
            return
        }
        action()
    }
}
