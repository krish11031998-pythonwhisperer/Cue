//
//  TimerReminderTasksView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 12/02/2026.
//

import SwiftUI
import VanorUI
import Model

struct TimerReminderTasksView: View {
    
    @Environment(Store.self) var store
    let reminderTaskModels: [ReminderTaskModel]
    let loggedReminders: Set<ReminderTaskModel>
    let selectedPresentedDetent: PresentationDetent?
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .center, spacing: 16) {
                    ForEach(reminderTaskModels.indices, id: \.self) { index in
                        reminderTaskRowBuilder(index)
                        .id(index)
                    }
                }
                .padding(.top, 20)
            }
        }
    }
    
    
    // MARK: - ReminderTaskRowBuilder
    
    @ViewBuilder
    private func reminderTaskRowBuilder(_ index: Int) -> some View {
        let task = reminderTaskModels[index]
        let reminderIsLogged = loggedReminders.contains(reminderTaskModels[index])
        ReminderTaskRowView(reminderTaskModel: reminderTaskModels[index],
                            isLogged: reminderIsLogged) {
            if reminderIsLogged {
                self.store.deleteTaskLogsFor(at: Date.now, for: task.objectId, completion: nil)
            } else {
                self.store.logReminderTask(at: Date.now, for: task.objectId, completion: nil)
            }
        }
    }
    
}

fileprivate struct ReminderTaskRowView: View {
    
    @Environment(Store.self) var store
    @State private var taskToSelected: Bool = false
    @State private var logged: Bool = false
    @State private var reminderTask: ReminderTaskModel?
    
    let reminderTaskModel: ReminderTaskModel
    let action: Callback
    
    init(reminderTaskModel: ReminderTaskModel, isLogged: Bool, action: @escaping Callback) {
        self.reminderTaskModel = reminderTaskModel
        self._logged = .init(initialValue: isLogged)
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
            withAnimation(.easeInOut) {
                self.taskToSelected = true
            }
        } label: {
            HStack(alignment: .center, spacing: 4) {
                ReminderIconView(icon: .init(reminderTaskModel.icon)!,
                                 foregroundColor: Color.proSky.baseColor,
                                 backgroundColor: Color.secondarySystemBackground,
                                 font: .footnote)
                
                Text(reminderTaskModel.title)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                ZStack(alignment: .center) {
                    if logged {
                        Circle()
                            .fill(Color.green)
                            .transition(.opacity)
                        
                        Image(systemSymbol: .checkmark)
                            .resizable()
                            .scaledToFit()
                            .padding(.all, 6)
                            .transition(.symbolEffect(.drawOn, options: .default).animation(.default.delay(0.1)))
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .stroke(Color.gray, style: .init(lineWidth: 1))
                    }
                }
                .frame(width: 24, height: 24, alignment: .center)
            }
            .padding(.horizontal, 20)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(height: 48, alignment: .center)
        .task(id: taskToSelected) {
            guard taskToSelected else { return }
            if logged {
                self.store.deleteTaskLogsFor(at: .now, for: reminderTaskModel.objectId) { wasSuccess in
                    self.logged = false
                }
            } else {
                self.store.logReminderTask(at: .now, for: reminderTaskModel.objectId) { wasSuccess in
                    self.logged = true
                }
            }
        }
        
    }
    
}
