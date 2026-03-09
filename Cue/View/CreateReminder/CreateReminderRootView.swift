//
//  CreateReminderRootView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 11/03/2026.
//

import SwiftUI
import VanorUI
import Model

struct CreateReminderRootView: View {
    enum Mode {
        case manual
        case ai
    }
    
    @Environment(\.dismiss) var dismiss
    @Environment(SubscriptionManager.self) var subscriptionManager
    @State private var mode: Mode = .ai
    let store: Store
    
    init(store: Store) {
        self.store = store
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .center) {
                switch mode {
                case .manual:
                    CreateReminderView(mode: .create, store: store) {
                        dismiss()
                    }
                    .transition(.blurReplace)
                case .ai:
                    CreateReminderWithCueAI(store: store)
                        .transition(.blurReplace)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("", systemSymbol: .xmark) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemSymbol: mode == .manual ? .sparkles2 : .pencilTip) {
                        withAnimation(.easeInOut) {
                            mode = mode == .ai ? .manual : .ai
                        }
                    }
                }
            }
        }
    }
}
