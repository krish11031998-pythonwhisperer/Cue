//
//  MainTab.swift
//  Cue
//
//  Created by Krishna Venkatramani on 17/01/2026.
//

import SwiftUI
import ColorTokensKit

struct MainTab: View {
    
    enum Tabs: Hashable {
        case home
    }
    
    @State private var selectedTab: Tabs = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: Tabs.home) {
                ContentView()
                    .tabItem {
                        Label("Reminder", systemImage: "calendar")
                    }
            }
        }
    }
    
}
