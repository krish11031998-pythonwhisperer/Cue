//
//  PaywallPresentation.swift
//  Cue
//
//  Created by Krishna Venkatramani on 13/09/2026.
//

import SwiftUI
import Combine

extension Notification.Name {
    static var presentPaywall: Notification.Name { .init(rawValue: "presentPayWall") }
}

/// Keeps track of every `paywallPresentation()` presenter currently on screen so a
/// `.presentPaywall` notification is only handled by the top-most one.
///
/// Without this the root `MainTab` presenter would answer a gate that was tapped inside a
/// sheet — swapping that sheet out for the paywall and taking any in-progress draft with it.
@MainActor
final class PaywallPresenterRegistry {
    
    static let shared = PaywallPresenterRegistry()
    
    private var stack: [UUID] = []
    
    private init() {}
    
    func register(_ id: UUID) {
        // `onAppear` can fire more than once for the same view; keep a single entry so the
        // matching `onDisappear` always clears it.
        stack.removeAll { $0 == id }
        stack.append(id)
    }
    
    func unregister(_ id: UUID) {
        stack.removeAll { $0 == id }
    }
    
    func isTopMost(_ id: UUID) -> Bool {
        stack.last == id
    }
}

private struct PaywallPresentationModifier: ViewModifier {
    
    @State private var id: UUID = .init()
    @State private var presentPaywall: Bool = false
    
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $presentPaywall) {
                CuePaywallView()
                    .presentationDetents([.fraction(1)])
            }
            .onReceive(NotificationCenter.default.publisher(for: .presentPaywall).receive(on: DispatchQueue.main)) { _ in
                guard PaywallPresenterRegistry.shared.isTopMost(id) else { return }
                self.presentPaywall = true
            }
            .onAppear { PaywallPresenterRegistry.shared.register(id) }
            .onDisappear { PaywallPresenterRegistry.shared.unregister(id) }
    }
}

extension View {
    
    /// Presents `CuePaywallView` when `SubscriptionManager.proUserAction(_:)` blocks a feature
    /// reached from this screen.
    ///
    /// Apply it to the app root and to any screen that is *always* presented modally and gates a
    /// pro feature — the paywall then stacks on top of that screen instead of replacing it. Do
    /// not apply it to tab content: a tab that does not reliably get `onDisappear` would stay
    /// registered as top-most and swallow paywalls asked for from another tab.
    func paywallPresentation() -> some View {
        modifier(PaywallPresentationModifier())
    }
}
