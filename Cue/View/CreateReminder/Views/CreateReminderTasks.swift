//
//  CreateReminderTasks.swift
//  Cue
//
//  Created by Krishna Venkatramani on 24/01/2026.
//

import SwiftUI
import VanorUI

struct CreateReminderTasksView: View {
    
    let canLoadSuggestions: Bool
    let isLoadingSuggestions: Bool
    let taskViewModels: [ReminderTaskView.Model]
    let addTask: (String) -> Void
    let deleteTask: (ReminderTaskView.Model) -> Void
    let generateTasks: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Section {
                if !taskViewModels.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(taskViewModels) { taskViewModel in
                            ReminderTaskView(model: taskViewModel)
                                .transition(.scale(scale: 1, anchor: .center))
                        }
                    }
                    .padding(.top, 16)
                }
            } header: {
                CreateReminderSectionHeaderView(canLoadSuggestions: canLoadSuggestions, isLoadingSuggestions: isLoadingSuggestions) {
                    generateTasks()
                }
            } footer: {
                CreateReminderSectionFooterView { taskName in
                    addTask(taskName)
                }
                .padding(.top, 12)
            }
        }
    }
    
}
