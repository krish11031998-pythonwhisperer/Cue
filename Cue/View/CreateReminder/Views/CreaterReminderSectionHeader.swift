//
//  CreaterReminderSectionHeader.swift
//  Cue
//
//  Created by Krishna Venkatramani on 20/01/2026.
//

import SwiftUI
import SFSafeSymbols
import ColorTokensKit
import VanorUI

struct CreateReminderSectionHeaderView: View {
    
    let action: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Add Tasks")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: action){
                Image(systemSymbol: .sparkles)
                    .font(.subheadline)
            }
            .tint(Color.proSky.baseColor)
            .buttonStyle(.glassProminent)
        }
    }
    
}
