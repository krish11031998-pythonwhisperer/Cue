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
        FocusTimerRootView(coordinator: coordinator, reminders: viewModel.calendarDay?.reminders ?? [])
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
            .onChange(of: viewModel.calendarDay?.reminders, initial: true) { oldValue, newValue in
                print("(DEBUG) reminders: \(newValue?.count ?? 0)")
            }
    }
    
}


#Preview {
    FocusTimerTabView(coordinator: .init(alarmCoordinator: nil))
}
