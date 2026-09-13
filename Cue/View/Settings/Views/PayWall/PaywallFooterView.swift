//
//  PaywallFooterView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 11/02/2026.
//

import SwiftUI
import VanorUI

struct PaywallFooterView: View {
    
    @Environment(\.dismiss) var dismiss
    let restoringPurchase: Bool
    let showButtonLoading: Bool
    let purchaseAction: () -> Void
    let restorePurchasesAction: () -> Void
    
    
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            CueLargeButton(action: purchaseAction) {
                Text("Continue")
                    .font(.headline)
                    .opacity(showButtonLoading ? 0 : 1)
                    .overlay(alignment: .center) {
                        if showButtonLoading {
                            ProgressView()
                        }
                    }
            }
            .disabled(showButtonLoading)
            
            HStack(alignment: .center, spacing: 8) {
                Button("Restore Purchase", action: restorePurchasesAction)
                .disabled(restoringPurchase)
                
                Button("Terms") {
                    UIApplication.shared.open(AppLink.termsOfUse)
                }
                
                Button("Privacy") {
                    UIApplication.shared.open(AppLink.privacyPolicy)
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 16)
    }
}
