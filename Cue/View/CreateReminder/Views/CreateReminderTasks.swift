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
    let taskRows: [ReminderTaskRow]
    let addTask: (String) -> Void
    let generateTasks: () -> Void
    
    var body: some View {
        Section {
            ForEach(taskRows) { row in
                ReminderTaskView(model: row.model)
                    .transition(.scale(scale: 1, anchor: .center))
            }
        } header: {
            CreateReminderSectionHeaderView(canLoadSuggestions: canLoadSuggestions, isLoadingSuggestions: isLoadingSuggestions) {
                generateTasks()
            }
        } footer: {
            CreateReminderSectionFooterView { taskName in
                addTask(taskName)
            }
            .padding(.top, taskRows.isEmpty ? 0 : 6)
        }
        .environment(\.createReminderStyle, .list)
    }
    
}
