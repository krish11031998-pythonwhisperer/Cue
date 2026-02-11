//
//  OnboardingMainview.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/02/2026.
//

import SwiftUI
import VanorUI
import Model

struct OnboardingMainView: View {
    
    enum Tabs: String, Identifiable, CaseIterable {
        case first
        case second
        case third
        case fourth
        case fifth
        
        var id: String { rawValue }
        
        func next() -> Tabs? {
            switch self {
            case .first:
                return .second
            case .second:
                return .third
            case .third:
                return .fifth
            case .fourth, .fifth:
                return nil
            }
        }
    }
    
    @Environment(\.dismiss) var dismiss
    @State private var tabs: Tabs = .first
    @State private var hideNextButton: Bool = false
    let store: Store
    
    
    var themeColor: Color {
        Color.proSky.baseColor
    }
    
    var body: some View {
        TabView(selection: $tabs) {
            ForEach(Tabs.allCases) { tab in
                Group {
                    switch tab {
                    case .first:
                        WelcomeOnboardingView()
                    case .second:
                        WelcomeAlarmAndNotificationView()
                    case .third:
                        WelcomeFocusView(isCurrentTab: tabs == tab) {
                            self.hideNextButton = false
                        }
                    case .fourth:
                        WelcomeHabitView(onAppear: tabs == tab) {
                            print("(DEBUG) longPress")
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(300))
                                tabs = .fifth
                            }
                        }
                    case .fifth:
                        WelcomeCreateReminderView(onAppear: tabs == tab)
                    }
                }
                .tag(tab)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .disabled(tabs != .second && tabs != .fourth)
        .safeAreaBar(edge: .bottom, alignment: .trailing, spacing: 8) {
            Button {
                if case .third = tabs {
                    self.tabs = tabs.next()!
                } else if case .fourth = tabs {
                    // Nothing to do
                } else if case .fifth = tabs {
                    dismiss()
                } else {
                    if case .second = tabs {
                        self.hideNextButton = true
                    }
                    withAnimation(.easeInOut) {
                        self.tabs = tabs.next()!
                    }
                }
            } label: {
                HStack(alignment: .center, spacing: 8) {
                    Text("Next")
                    Image(systemSymbol: .arrowRight)
                }
                .font(.headline)
                .padding(.init(top: 8, leading: 14, bottom: 8, trailing: 14))
            }
            .tint(Color.proSky.baseColor)
            .buttonStyle(.glassProminent)
            .padding(.horizontal, 16)
            .animation(.easeInOut) { content in
                content
                    .opacity(hideNextButton ? 0 : 1)
                    .disabled(hideNextButton)
            }
        }
        .background(alignment: .bottom) {
            ZStack(alignment: .center) {
                if tabs != .fifth {
                    RadialGradient(stops: [.init(color: themeColor, location: 0), .init(color: themeColor.opacity(0.1), location: 1)], center: .bottom, startRadius: 0, endRadius: 300)
                } else {
                    GeometryReader { proxy in
                        let bubbleStartSize = proxy.size.smallDim - 40
                        ExpandingCircle(startFrame: .init(origin: .init(x: (proxy.size.width - bubbleStartSize).half, y: (proxy.size.height - bubbleStartSize).half), size: .init(squared: bubbleStartSize)),
                                        finalCornerRadius: 0,
                                        pct: tabs == .fifth  ? 1 : 0)
                        .fill(Color.proSky.backgroundTertiary)
                    }
                }
            }
            .ignoresSafeArea(edges: .vertical)
            .animation(.easeInOut, value: tabs)
        }
        .task {
            CueUserDefaultsManager.shared[.hasShowOnboarding] = true
        }
    }
    
}

#Preview {
    OnboardingMainView(store: .init())
}
