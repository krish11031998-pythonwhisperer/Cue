//
//  CueProSubscriptionGuidelines.swift
//  Cue
//
//  Created by Krishna Venkatramani on 11/02/2026.
//

import SwiftUI

/// The auto-renewable subscription terms rendered under the plan list on `CuePaywallView`.
///
/// Guideline 3.1.2(c) requires these to appear in the purchase flow itself, not only in the
/// App Store description. `allCases` order is render order, so keep it payment → renew → cancel
/// and keep the wording in step with the legal block in `app-store-legal-block.txt` — the two
/// must not drift.
enum CueProSubscriptionGuidelines: String, CaseIterable {
    case payment
    case renew
    case cancel
    
    var message: String {
        switch self {
        case .payment:
            "• Payment is charged to your Apple Account at confirmation of purchase."
        case .renew:
            "• Subscription renews automatically for the same period and price unless canceled at least 24 hours before the end of the current period."
        case .cancel:
            "• Cancel anytime in your Apple Account settings. Any unused portion of a free trial is forfeited when you purchase a subscription."
        }
    }
}
