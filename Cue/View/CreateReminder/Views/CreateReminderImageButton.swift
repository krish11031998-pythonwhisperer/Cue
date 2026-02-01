//
//  CreateReminderImageView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 25/01/2026.
//

import SwiftUI
import VanorUI

struct CreateReminderImageButton: View {
    
    let color: Color
    let icon: Icon
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Group {
                switch icon {
                case .emoji(let emoji):
                    EmojiImageView(emoji: emoji)
                        .aspectRatio(contentMode: .fit)
                case .symbol(let symbol):
                    Image(systemSymbol: symbol)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
            }
            .padding(.all, 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .containerShape(.circle)
        }
        .tint(color)
        .buttonStyle(.glassProminent)
        .aspectRatio(1, contentMode: .fit)

    }
}
