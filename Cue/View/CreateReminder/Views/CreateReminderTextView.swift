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
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
            } label: {
                Image(systemSymbol: selectedSymbol)
                    .font(.headline)
//                    .frame(maxWidth: .infinity, alignment: .center)
//                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: 54, height: 54, alignment: .center)
            }
            .tint(Color.proSky.baseColor)
            .buttonStyle(.glassProminent)
            
            TextField("Create Reminder",
                      text: $reminderTitle,
                      axis: .vertical)
            .font(.title)
            .fontWeight(.medium)
        }
    }
    
}
