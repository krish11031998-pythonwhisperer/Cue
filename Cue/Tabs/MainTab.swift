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
    
    enum FullScreenPresentation: String, Identifiable {
        case onboarding
        
        var id: String { rawValue }
    }
    
    @Environment(Store.self) var store
    private let hasShowOnboarding: Bool
    @State private var selectedTab: Tabs = .home
    @State private var presentCreateReminder: Bool = false
    @State private var fullScreenPresentation: FullScreenPresentation? = nil
    
    init() {
        self.hasShowOnboarding = CueUserDefaultsManager.shared[.hasShowOnboarding] ?? false
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
            }
            
            Tab(value: .organize) {
                OrangizeTabView()
            } label: {
                Label {
                    Text("Organize")
                } icon: {
                    Image(systemSymbol: .clipboardFill)
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
        .sheet(isPresented: $presentCreateReminder) {
            CreateReminderView(mode: .create, store: store)
                .presentationDetents([.fraction(1)])
        }
        .task {
            guard !hasShowOnboarding else { return }
            self.fullScreenPresentation = .onboarding
        }
        .fullScreenCover(item: $fullScreenPresentation,
                         onDismiss: {
            self.presentCreateReminder = true
        }) { fullScreenPresentation in
            switch fullScreenPresentation {
            case .onboarding:
                OnboardingMainView(store: store)
            @unknown default:
                fatalError("This shouldn't happen")
            }
        }
    }
    
}
