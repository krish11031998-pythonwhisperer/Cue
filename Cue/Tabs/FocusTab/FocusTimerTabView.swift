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

extension Notification.Name {
    static let presentQuickStart = Notification.Name("presentQuickStart")
}

struct FocusTimerTabView: View {
    
    @Bindable private var coordinator: FocusSessionCoordinator
    @State private var viewModel: FocusTimeViewModel = .init()
    @Environment(Store.self) var store
    
    init(coordinator: FocusSessionCoordinator) {
        self.coordinator = coordinator
    }
    
    var body: some View {
        #if NEW_COUNTDOWN_TIMER
        FocusRootView(coordinator: coordinator)
        #else
        FTQuickStartView(coordinator: coordinator, reminders: viewModel.calendarDay?.reminders ?? [])
            .task {
                await viewModel.fetchRemindersForToday()
            }
            .tabBarMinimizeBehavior(.automatic)
            .onChange(of: viewModel.calendarDay?.reminders, initial: true) { oldValue, newValue in
                print("(DEBUG) reminders: \(newValue?.count ?? 0)")
            }
        #endif
    }
    
}


#Preview {
    FocusTimerTabView(coordinator: .previawableSessionCoordinator)
}
