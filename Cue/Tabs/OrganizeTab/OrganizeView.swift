//
//  OrganizeView.swift
//  Model
//
//  Created by Krishna Venkatramani on 12/02/2026.
//

import SwiftUI
import Model
import VanorUI

struct OrangizeTabView: View {
    @Environment(Store.self) var store
    @Environment(SubscriptionManager.self) var subscriptionManager
    @State private var viewModel: OrganizeTabViewModel = .init()
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .center) {
                if viewModel.reminders.isEmpty == false {
                    ScrollView(.vertical) {
                        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                            Section {
                                ForEach(viewModel.reminders, id: \.self) { reminderModel in
                                    ReminderView(model: reminderModel)
                                        .padding(.horizontal, 20)
                                        .padding(.bottom, 12)
                                }
                            } header: {
                                OrganizeScrollHeaderView(chipViewModels: viewModel.tagChipView)
                                .padding(.bottom, 16)
                            }
                        }
                        .animation(.easeInOut, value: viewModel.reminders)
                        .padding(.top, 20)
                    }
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
            let store = store.backgroundContext()
            let tags = Array(viewModel.selectedTag)
            if tags.isEmpty {
                let reminders = await OrganizeFilterController.shared.fetchReminders(with: store, type: .all)
                viewModel.populateReminderViewModel(reminders)
            } else {
                let reminders = await OrganizeFilterController.shared.fetchReminders(with: store, type: .tags(tags.map(\.name)))
                viewModel.populateReminderViewModel(reminders)
            }
        }
        .task(id: store.tags, {
            self.viewModel.tagModel(store.tags)
        })
        .sheet(item: $viewModel.selectedPresentation) { presentation in
            switch presentation {
            case .tags:
                CreateTagView { tagName, color in
                    store.createTag(name: tagName, color: color.asUIColor)
                }
                .fittedPresentationDetent()
            }
        }
    }
    
}

