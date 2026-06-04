//
//  FocusTimerTabView.swift
//  Kyu
//
//  Created by Krishna Venkatramani on 05/04/2026.
//

import Foundation
import SwiftUI
import VanorUI
import Model

struct FocusTimerTabView: View {
    
    @Bindable private var coordinator: FocusTimerLaunchControlCoordinator
    @State private var viewModel: FocusTimeViewModel = .init()
    @Environment(Store.self) var store
    
    init(coordinator: FocusTimerLaunchControlCoordinator) {
        self.coordinator = coordinator
    }
    
    var body: some View {
        Group {
            if let calendarDay = viewModel.calendarDay {
                // Need to add a static view
                FocusCountdownRootView(coordinator: coordinator, reminders: calendarDay.reminders)
            } else {
                ProgressView()
            }
        }
        .task {
            await viewModel.fetchRemindersForToday()
        }
        .tabBarMinimizeBehavior(.automatic)
        .sheet(isPresented: $coordinator.showTasksSheet) {
            NavigationView {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        
                    }
                }
                .navigationTitle("Tasks")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(role: .close) {
                            coordinator.showTasksSheet = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
    
}


#Preview {
    FocusTimerTabView(coordinator: .init())
}
