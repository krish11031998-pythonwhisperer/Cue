//
//  CreateReminderTasks.swift
//  Cue
//
//  Created by Krishna Venkatramani on 24/01/2026.
//

import SwiftUI
import VanorUI

struct CreateReminderTasksView: View {
    
    struct Actions {
        let addTask: (String) -> Void
        let generateTasks: () -> Void
        let renameTask: (UUID, String) -> Void
        let deleteTask: (UUID) -> Void
    }
    
    let canLoadSuggestions: Bool
    let isLoadingSuggestions: Bool
    let taskViewModels: [ReminderTaskRow]
    let actions: Actions
//    let addTask: (String) -> Void
//    let generateTasks: () -> Void
    
    var body: some View {
        Section {
            ForEach(taskViewModels) { taskViewModel in
                ReminderTaskView(model: reminderTaskViewModel(for: taskViewModel))
                    .transition(.scale(scale: 1, anchor: .center))
            }
        } header: {
            CreateReminderSectionHeaderView(canLoadSuggestions: canLoadSuggestions, isLoadingSuggestions: isLoadingSuggestions) {
                actions.generateTasks()
            }
        } footer: {
            CreateReminderSectionFooterView { taskName in
                actions.addTask(taskName)
            }
            .padding(.top, taskViewModels.isEmpty ? 0 : 6)
        }
        .environment(\.createReminderStyle, .list)
    }
    
    private func reminderTaskViewModel(for reminderRow: ReminderTaskRow) -> ReminderTaskView.Model {
        let edit: (String) -> Void = { name in
            actions.renameTask(reminderRow.id, name)
        }
        
        let delete: Callback = {
            actions.deleteTask(reminderRow.id)
        }
        
        let viewType = ReminderTaskView.ViewType.displayOnly(edit, delete, { })
        
        return .init(taskTitle: reminderRow.title, icon: reminderRow.icon, viewType: viewType)
    }
    
}
