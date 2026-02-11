//
//  CueProSubscriptionGuidelines.swift
//  Cue
//
//  Created by Krishna Venkatramani on 11/02/2026.
//

import SwiftUI

enum CueProSubscriptionGuidelines: String, CaseIterable {
    case cancel
    case renew
    
    var message: String {
        switch self {
        case .cancel:
            "• Cancel anytime in your App Store account settings."
        case .renew:
            "• Subscription renews automatically unless canceled at least 24 hours before renewal."
        }
    }
}
