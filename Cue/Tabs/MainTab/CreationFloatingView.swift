//
//  CreationFloatingView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 31/07/2026.
//

import SwiftUI
import VanorUI

#warning("Move VanorUI")
fileprivate struct FloatButtonLabelStyle: LabelStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 10) {
            configuration.title
                .font(.bitcountRegular(style: .headline))
                .disabled(true)
            configuration.icon
                .font(.headline)
                .foregroundStyle(.primary)
                .frame(width: 48, height: 48, alignment: .center)
                .glassEffect(.regular.tint(.clear).interactive(true), in: .circle)
        }
    }
    
}

struct CreationFloatingView: View {
    
    typealias Presentation = MainTabViewModel.Presentation
    
    @Environment(SubscriptionManager.self) var subscriptionManager
    @Binding var presentation: Presentation?
    @Binding var presentFloatingMenu: Bool
    
    enum ButtonType: String, Identifiable, CaseIterable {
        case createRoutineWithAI
        case createRoutine
        
        var image: SFSymbol {
            switch self {
            case .createRoutineWithAI:
                return .wandAndRays
            case .createRoutine:
                return .pencil
            }
        }
        
        var title: String {
            switch self {
            case .createRoutineWithAI:
                return "cue:ai"
            case .createRoutine:
                return "Create"
            }
        }
        
        var id: String { rawValue }
    }
    
    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .center, spacing: 8) {
                ForEach(ButtonType.allCases) { buttonType in
                    Button {
                        self.buttonAction(for: buttonType)
                    } label: {
                        Label {
                            Text(buttonType.title)
                        } icon: {
                            Image(systemSymbol: buttonType.image)
                        }
                        .labelStyle(FloatButtonLabelStyle())
                    }
                    .buttonStyle(.plain)
                    .transition(.scale(scale: 0.9).animation(.easeInOut))
                }
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
        }
        .animation(.easeInOut, value: presentFloatingMenu)
    }
    
    
    // MARK: - Button Action
    
    private func buttonAction(for type: ButtonType) {
        switch type {
        case .createRoutineWithAI:
            self.presentation = .createReminderWithAI
        case .createRoutine:
            self.presentation = .createReminder
        }
    }
}
