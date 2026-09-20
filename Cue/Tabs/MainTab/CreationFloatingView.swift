//
//  CreationFloatingView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 31/07/2026.
//

import SwiftUI
import VanorUI
import FoundationModels

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
    @State private var animationToPresent: Bool = false
    
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
    
    /// cue:ai generates its reminders on-device, so the button is only offered where that model
    /// is usable — on every other device the menu is just `Create`.
    private var availableButtons: [ButtonType] {
        ButtonType.allCases.filter { buttonType in
            switch buttonType {
            case .createRoutineWithAI:
                return SystemLanguageModel.supportsCueAI
            case .createRoutine:
                return true
            }
        }
    }
    
    private func insets(proxy: GeometryProxy) -> EdgeInsets {
        .init(top: 0,
              leading: proxy.safeAreaInsets.leading,
              bottom: proxy.safeAreaInsets.bottom + 24,
              trailing: proxy.safeAreaInsets.trailing + 24)
    }
    
    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomTrailing) {
                Color.clear
                if animationToPresent {
                    ButtonStack(buttons: availableButtons) {
                        self.buttonAction(for: $0)
                    }
                    .transition(.peekover(identity: .toIdentity).combined(with: .opacity.animation(.easeInOut(duration: 0.1))))
                    .padding(insets(proxy: proxy))
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.snappy(duration: 0.3)) {
                    self.animationToPresent = false
                } completion: {
                    self.presentFloatingMenu = false
                }
            }
        }
        .onAppear {
            withAnimation(.snappy(duration: 0.3)) {
                self.animationToPresent = true
            }
        }
    }
    
    
    // MARK: ButtonStacks
    
    private struct ButtonStack: View {
        let buttons: [ButtonType]
        let action: (ButtonType) -> Void
        
        var body: some View {
            VStack(alignment: .center, spacing: 8) {
                ForEach(buttons) { buttonType in
                    Button {
                        self.action(buttonType)
                    } label: {
                        Label {
                            Text(buttonType.title)
                        } icon: {
                            Image(systemSymbol: buttonType.image)
                        }
                        .labelStyle(FloatButtonLabelStyle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .fixedSize()
        }
    }
    
    // MARK: - Button Action
    
    private func buttonAction(for type: ButtonType) {
        switch type {
        case .createRoutineWithAI:
            subscriptionManager.proUserAction {
                self.presentation = .createReminderWithAI
            }
        case .createRoutine:
            self.presentation = .createReminder
        }
    }
}
