//
//  MainTab.swift
//  Cue
//
//  Created by Krishna Venkatramani on 17/01/2026.
//

import SwiftUI
import ColorTokensKit
import Model

struct MainTab: View {
    
    enum Tabs: Hashable {
        case home
    }
    
    private let store: Store
    @State private var selectedTab: Tabs = .home
    
    init(store: Store) {
        self.store = store
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: Tabs.home) {
                TodayTabView(store: store)
                    .tabItem {
                        Label {
                            Text("Reminders")
                        } icon: {
                            Image(systemName: "calendar")
                        }
                    }
            }
        }
    }
    
}
