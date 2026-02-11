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
                    UIApplication.shared.open(URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                }
                
                Button("Privacy") {
                    UIApplication.shared.open(.init(string: "https://sparkling-tablecloth-441.notion.site/cue-it-Privacy-Policy-45224c4d70314ccf893c25e919ae836a")!)
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
    }
}
