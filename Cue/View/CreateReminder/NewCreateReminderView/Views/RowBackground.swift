//
//  RowBackground.swift
//  Cue
//
//  Created by Krishna Venkatramani on 02/08/2026.
//

import SwiftUI

struct RowBackground: ViewModifier {
    
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background {
                if colorScheme == .light {
                    Rectangle()
                        .fill(Color.white.opacity(0.25))
                } else {
                    Rectangle()
                        .fill(Color.white.opacity(0.05))
                }
            }
    }
}
