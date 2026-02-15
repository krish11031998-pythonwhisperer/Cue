//
//  OrganizeView.swift
//  Model
//
//  Created by Krishna Venkatramani on 12/02/2026.
//

import SwiftUI
import Model
import VanorUI
import AsyncAlgorithms

struct OrangizeTabView: View {
    @Environment(Store.self) var store
    @Environment(SubscriptionManager.self) var subscriptionManager
    @State private var viewModel: OrganizeTabViewModel = .init()
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .center) {
                ScrollView(.vertical) {
                    if viewModel.reminders.isEmpty == false {
                        cellViews
                    } else {
                        ContentUnavailableView {
                            Image(systemSymbol: .trayFill)
                                .font(.largeTitle)
                        } description: {
                            Text("No Reminders")
                                .font(.title)
                                .fontWeight(.semibold)
                        } actions: {
                            Text("You have nothing in your inbox. Start by creating a new reminder.")
                                .font(.footnote)
                                .fontWeight(.semibold)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            }
            .navigationTitle("Organize")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if subscriptionManager.userIsPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("", systemSymbol: .plus) {
                            viewModel.selectedPresentation = .tags
                        }
                    }
                }
            }
        }
        .task(id: viewModel.mode) {
            guard viewModel.reminders.isEmpty == false else { return }
            await updateReminders()
        }
        .task(id: store.reminders) {
            await updateReminders()
        }
        .task(id: store.tags) {
            self.viewModel.tagModel(store.tags)
        }
        .sheet(item: $viewModel.selectedPresentation) { presentation in
            switch presentation {
            case .tags:
                CreateTagView { tagName, color in
                    store.createTag(name: tagName, color: color.asUIColor)
                }
                .fittedPresentationDetent()
            case .reminder(let reminderModel):
                CreateReminderView(mode: .edit(reminderModel), store: store)
            }
        }
    }
    
    
    // MARK: - Cells
    
    private var cellViews: some View {
        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
            Section {
                ForEach(viewModel.reminders) { reminder in
                    OrganizeReminderCellView(reminderViewModel: reminder.cellViewModel) {
                        self.viewModel.selectedPresentation = .reminder(reminder.reminder)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                }
            } header: {
                if viewModel.tagChipView.isEmpty == false {
                    OrganizeScrollHeaderView(chipViewModels: viewModel.tagChipView)
                        .padding(.bottom, 16)
                }
            }
        }
        .animation(.easeInOut, value: viewModel.reminders)
        .padding(.top, 20)
    }
    
    
    // MARK: - Update Calls
    
    private func updateReminders() async {
        let backgroundContext = store.backgroundContext()
//        let tags = Array(viewModel.selectedTag)
//        let reminders: [ReminderModel]
//        if tags.isEmpty {
//            reminders = await OrganizeFilterController.shared.fetchReminders(with: backgroundContext, type: .all)
//        } else {
//            reminders = await OrganizeFilterController.shared.fetchReminders(with: backgroundContext, type: .tags(tags.map(\.name)))
//        }
//        
//        guard !Task.isCancelled else { return }
//        viewModel.populateReminderViewModel(reminders)
        await viewModel.updateReminder(with: backgroundContext)
    }
}

fileprivate struct OrganizeReminderCellView: View {
    
    let reminderViewModel: ReminderView.Model
    let action: () -> Void
    
    init(reminderViewModel: ReminderView.Model, action: @escaping () -> Void) {
        self.reminderViewModel = reminderViewModel
        self.action = action
    }
    
    var body: some View {
        Button {
            print("(DEBUG) Reminder tapped")
            action()
        } label: {
            ReminderView(model: reminderViewModel)
        }
        .buttonStyle(.plain)
    }
    
}

