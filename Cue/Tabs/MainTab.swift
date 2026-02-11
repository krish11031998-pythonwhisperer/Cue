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
        case settings
        case create
    }
    
    enum FullScreenPresentation: String, Identifiable {
        case onboarding
        
        var id: String { rawValue }
    }
    
    private let store: Store
    private let hasShowOnboarding: Bool
    @State private var selectedTab: Tabs = .home
    @State private var presentCreateReminder: Bool = false
    @State private var fullScreenPresentation: FullScreenPresentation? = nil
    
    init(store: Store) {
        self.store = store
        self.hasShowOnboarding = CueUserDefaultsManager.shared[.hasShowOnboarding] ?? false
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: Tabs.home) {
                TodayTabView {
                    self.presentCreateReminder = true
                }
            } label: {
                Label {
                    Text("Reminders")
                } icon: {
                    Image(systemName: "calendar")
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
