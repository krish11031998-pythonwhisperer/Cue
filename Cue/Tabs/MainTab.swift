//
//  MainTab.swift
//  Cue
//
//  Created by Krishna Venkatramani on 17/01/2026.
//

import SwiftUI
import VanorUI
import Model

struct MainTab: View {
    
    enum Tabs: Hashable {
        case home
        case organize
        case settings
        case create
    }
    
    enum Presentation: Int, Identifiable {
        case createReminder = 0
        case paywall
        
        var id: Int { rawValue }
    }
    
    enum FullScreenPresentation: String, Identifiable {
        case onboarding
        
        var id: String { rawValue }
    }
    
    @Environment(Store.self) var store
    @Environment(SubscriptionManager.self) var subscriptionManager
    private let hasShowOnboarding: Bool
    @State private var selectedTab: Tabs = .home
    @State private var presentCreateReminder: Bool = false
    @State private var fullScreenPresentation: FullScreenPresentation? = nil
    @State private var presentPayWall: Bool = false
    private let presentPayWallAfterFirstOnboarding: Bool
    
    init() {
        self.hasShowOnboarding = CueUserDefaultsManager.shared[.hasShowOnboarding] ?? false
        presentPayWallAfterFirstOnboarding = !hasShowOnboarding
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: Tabs.home) {
                TodayTabView {
                    self.presentCreateReminder = true
                }
                .ignoresSafeArea(edges: .bottom)
            } label: {
                Label {
                    Text("Reminders")
                } icon: {
                    Image(systemName: "calendar")
                }
                .tint(Color.proSky.baseColor)
            }
            
            if subscriptionManager.userIsPro {
                Tab(value: .organize) {
                    OrangizeTabView()
                } label: {
                    Label {
                        Text("Organize")
                    } icon: {
                        Image(systemSymbol: .clipboardFill)
                    }
                    .tint(Color.proSky.baseColor)
                    
                }
            }
            
            Tab(value: Tabs.settings) {
                SettingView()
            } label: {
                Label {
                    Text("Settings")
                } icon: {
                    Image(systemSymbol: .gearshapeFill)
                }
                .tint(Color.proSky.baseColor)
            }

            
            Tab("", systemImage: "plus", value: .create, role: .search) {
                Color.clear
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: selectedTab) { oldValue, newValue in
            if newValue == .create {
                self.presentCreateReminder = true
                self.selectedTab = oldValue
            }
        }
        .onChange(of: fullScreenPresentation, initial: false, { oldValue, newValue in
            if oldValue == .onboarding {
                self.presentCreateReminder = true
            }
        })
        .sheet(isPresented: $presentCreateReminder, onDismiss: {
            if presentPayWallAfterFirstOnboarding {
                presentPayWall = true
            }
        }) {
            CreateReminderView(mode: .create, store: store)
                .presentationDetents([.fraction(1)])
        }
        .sheet(isPresented: $presentPayWall) {
            CuePaywallView()
                .presentationDetents([.fraction(1)])
        }
        .task {
            guard !hasShowOnboarding else { return }
            self.fullScreenPresentation = .onboarding
        }
        .fullScreenCover(item: $fullScreenPresentation) { fullScreenPresentation in
            switch fullScreenPresentation {
            case .onboarding:
                OnboardingMainView(store: store)
            @unknown default:
                fatalError("This shouldn't happen")
            }
        }
    }
    
}
