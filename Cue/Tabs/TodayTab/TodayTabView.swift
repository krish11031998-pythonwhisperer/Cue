//
//  TodayTabView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 19/01/2026.
//

import Foundation
import SwiftUI
import Model
import VanorUI
import SFSafeSymbols
import ColorTokensKit
import KKit

struct TodayTabView: View {
    
    enum Presentation: Int, Identifiable {
        case addReminder = 0
        
        var id: Int { rawValue }
    }
    
    let store: Store
    @State private var presentation: Presentation? = nil
    @State private var viewModel: TodayViewModel = .init()
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .center) {
                Color(uiColor: .systemBackground)
                if store.reminders.isEmpty {
                    ContentUnavailableView("No Reminders", systemImage: "bell.fill", description: descriptionText)
                        .font(.headline)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            TimeCompactSwiftUIView(model: .init(elements: []))
                                .padding(.bottom, 32)
                            ForEach(store.reminders.indices, id: \.self) { index in
                                let reminder = store.reminders[index]
                                reminderBuilder(reminder)
                                    .padding(.bottom, 8)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.presentation = .addReminder
                    } label: {
                        Image(systemSymbol: .plus)
                            .font(.body)
                    }

                }
            }
        }
        .sheet(item: $presentation) { presentation in
            switch presentation {
            case .addReminder:
                CreateReminderView(store: store)
                    .presentationDetents([.fraction(1)])
            }
        }
    }
    
    
    // MARK: - DescriptionText
    
    private var descriptionText: Text {
        Text("Add Reminders to start organizing your day.")
            .font(.caption)
            .foregroundColor(.foregroundSecondary)
    }
    
    @ViewBuilder
    private func reminderBuilder(_ reminder: Reminder) -> some View {
        let tasks: [ReminderView.TaskModel] = reminder.tasksContainer.tasks.map { .init(title: $0.title, iconName: $0.icon) }
        let isExpanded = !tasks.isEmpty && viewModel.expandedReminder.contains(reminder)
        let model: ReminderView.Model = .init(title: reminder.title,
                                              icon: .init(rawValue: reminder.iconName),
                                              theme: Color.proSky,
                                              time: reminder.date,
                                              state: .hasLogged(.init(hasLogged: false)),
                                              showTask: isExpanded,
                                              tasks: tasks) { [weak viewModel] in
            viewModel?.logReminder(reminder)
        } expandReminder: { [weak viewModel] in
            withAnimation(.snappy) {
                viewModel?.expandReminder(reminder)
            }
        }
        
        ReminderView(model: model)
    }
}
