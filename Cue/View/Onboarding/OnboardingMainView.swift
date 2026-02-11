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
    }
    
    @Environment(\.dismiss) var dismiss
    @State private var tabs: Tabs = .first
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
                        WelcomeFocusView(isCurrentTab: tabs == tab)
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
                switch tabs {
                case .first:
                    withAnimation(.easeInOut) {
                        tabs = .second
                    }
                case .second:
                    withAnimation(.easeInOut) {
                        tabs = .third
                    }
                case .third:
                    withAnimation(.easeInOut) {
                        tabs = .fourth
                    }
                case .fourth:
                    tabs = .fifth
                case .fifth:
                    #if RELEASE
                    CueUserDefaultsManager.shared[.hasShowOnboarding] = true
                    #endif
                    dismiss()
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
                    .opacity(tabs == .fourth ? 0 : 1)
                    .disabled(tabs == .fourth)
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
