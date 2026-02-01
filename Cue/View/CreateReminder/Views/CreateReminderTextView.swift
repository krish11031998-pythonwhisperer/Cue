//
//  CreateReminderTextView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 20/01/2026.
//

import SwiftUI
import Combine
//import SFSafeSymbols
import VanorUI
//import ColorTokensKit

struct CreateReminderTextView: View {
    
    @Binding var selectedSymbol: SFSymbol
    @Binding var reminderTitle: String
    var presentSheet: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button(action: presentSheet) {
                Image(systemSymbol: selectedSymbol)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            .tint(Color.proSky.baseColor)
            .buttonStyle(.glassProminent)
            .aspectRatio(1, contentMode: .fit)
            .frame(width: 54)
            
            TextField("Create Reminder",
                      text: $reminderTitle,
                      axis: .vertical)
            .font(.title)
            .fontWeight(.medium)
        }
    }
    
}
