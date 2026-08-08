//
//  CreationFloatingView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 31/07/2026.
//

import SwiftUI
import VanorUI

struct CreationFloatingView: View {
    
    typealias Presentation = MainTabViewModel.Presentation
    
    @Binding var presentation: Presentation?
    @Binding var presentFloatingMenu: Bool
    
    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .center, spacing: 8) {
                Button {
                    self.presentation = .createReminderWithAI
                } label: {
                    Image(systemSymbol: .wandAndRays)
                }
                .buttonStyle(.accessoryButton(size: .large, color: .clear))
                
                Button {
                    self.presentation = .createReminder
                } label: {
                    Image(systemSymbol: .pencil)
                }
                .buttonStyle(.accessoryButton(size: .large, color: .clear))
            }
            .padding(.init(top: 0,
                           leading: proxy.safeAreaInsets.leading,
                           bottom: proxy.safeAreaInsets.bottom + 24,
                           trailing: proxy.safeAreaInsets.trailing + 24))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .contentShape(Rectangle())
            .onTapGesture {
                self.presentFloatingMenu = false
            }
            .transition(.opacity)
        }
    }
}
