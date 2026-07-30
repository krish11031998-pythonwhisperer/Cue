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
    #if AI_TAB
    @State private var mode: Mode? = nil
    #else
    @State private var mode: Mode = .ai
    #endif
    let store: Store
    
    init(store: Store) {
        self.store = store
    }
    
    var body: some View {
        #if AI_TAB
        NavigationView {
            CreateReminderWithCueAI(store: store)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("", systemSymbol: .pencilTip) {
                            withAnimation(.easeInOut) {
                                mode = .manual
                            }
                        }
                    }
                }
        }
        .sheet(isPresented: .init(get: { mode == .manual }, set: { _ in mode = nil }), onDismiss: nil) {
            NavigationView {
                CreateReminderView(mode: .create, store: store)
            }
            .presentationDetents([.large])
            .interactiveDismissDisabled(true)
        }
        #else
        NavigationView {
            ZStack(alignment: .center) {
                switch mode {
                case .manual:
                    #if NEW_CREATE_REMINDER
                    NewCreateReminderView(mode: .create, store: store) {
                        dismiss()
                    }
                        .transition(.blurReplace)
                    #else
                    CreateReminderView(mode: .create, store: store) {
                        dismiss()
                    }
                    .transition(.blurReplace)
                    #endif
                case .ai:
                    CueAIView(store: store)
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
        #endif
    }
}
