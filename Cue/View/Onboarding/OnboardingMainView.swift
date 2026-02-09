//
//  OnboardingMainview.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/02/2026.
//

import SwiftUI
import VanorUI

struct OnboardingMainView: View {
    
    enum Tabs: String, Identifiable, CaseIterable {
        case first
        case second
        case third
        case fourth
        
        var id: String { rawValue }
    }
    
    @State private var tabs: Tabs = .first
    
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
                        WelcomeHabitView {
                            withAnimation(.easeOut) {
                                self.tabs = .third
                            }
                        }
                    case .third:
                        WelcomeFocusView()
                    case .fourth:
                        Color.indigo
                            .ignoresSafeArea(edges: .all)
                    }
                }
                .tag(tab)
            }
        }
        .safeAreaBar(edge: .bottom, alignment: .trailing, spacing: 0) {
            Button {
                withAnimation(.easeInOut) {
                    switch tabs {
                    case .first:
                        tabs = .second
                    case .second:
                        break
                    case .third:
                        tabs = .fourth
                    case .fourth:
                        break
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
                    .opacity(tabs == .second ? 0 : 1)
                    .disabled(tabs == .second)
            }
        }
//        .ignoresSafeArea(edges: .all)
        .tabViewStyle(.page(indexDisplayMode: .never))
        .background(alignment: .bottom) {
            RadialGradient(stops: [.init(color: themeColor, location: 0), .init(color: themeColor.opacity(0.1), location: 1)], center: .bottom, startRadius: 0, endRadius: 300)
                .ignoresSafeArea(edges: .vertical)
        }
    }
    
}

#Preview {
    OnboardingMainView()
}
