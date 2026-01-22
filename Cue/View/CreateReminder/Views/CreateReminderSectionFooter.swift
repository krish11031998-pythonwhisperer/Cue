//
//  CreateReminderSectionFooter.swift
//  Cue
//
//  Created by Krishna Venkatramani on 20/01/2026.
//

import SwiftUI
import SFSafeSymbols
import ColorTokensKit
import VanorUI

struct CreateReminderSectionFooterView: View {
    
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label {
                Text("Add")
            } icon: {
                Image(systemSymbol: .plus)
            }
            .font(.footnote)
            .fontWeight(.semibold)
        }
        .buttonStyle(.glass)
    }
    
}
