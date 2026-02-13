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
    
    let reminderTaskModels: [ReminderTaskModel]
    let selectedPresentedDetent: PresentationDetent?
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .center, spacing: 16) {
                    ForEach(reminderTaskModels.indices, id: \.self) { index in
                        ReminderTaskRowView(reminderTaskModel: reminderTaskModels[index]) {
                            print("(DEBUG) fixing this task")
                        }
                        .id(index)
                    }
                }
                .padding(.top, 20)
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
                            .frame(width: 20, height: 20, alignment: .center)
                            .transition(.symbolEffect(.drawOn, options: .default).animation(.default.delay(0.1)))
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .stroke(Color.gray, style: .init(lineWidth: 1))
                    }
                }
                .frame(width: 32, height: 32, alignment: .center)
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
                    self.logged = wasSuccess
                }
            } else {
                self.store.logReminderTask(at: .now, for: reminderTaskModel.objectId) { wasSuccess in
                    self.logged = wasSuccess
                }
            }
        }
        
    }
    
}
