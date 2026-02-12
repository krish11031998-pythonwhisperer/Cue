//
//  TagView.swift
//  Model
//
//  Created by Krishna Venkatramani on 12/02/2026.
//

import SwiftUI
import Model
import VanorUI

struct TagView: View {
    
    @Environment(Store.self) var store
    @State private var viewModel: TagViewModel
    let onDismiss: ([TagModel]) -> Void
    @Environment(\.dismiss) var dismiss
    
    init(preSelected: [TagModel], onDismiss: @escaping ([TagModel]) -> Void) {
        self._viewModel = .init(initialValue: .init(preSelectedTags: preSelected))
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if viewModel.sectionedTags.isEmpty {
                    noTagsView
                } else {
                    List {
                        ForEach(viewModel.sectionedTags.enumerated(), id: \.element) { section in
                            Section {
                                ForEach(section.element.tags.enumerated(), id: \.offset) { tag in
                                    TagCellView(tag: tag.element,
                                                backgroundShape: listBackground(for: tag.offset, limit: section.element.tags.count - 1),
                                                selected: viewModel.selectedTags.contains(tag.element) ,
                                                selectTag: viewModel.selectTag(_:))
                                    
                                }
                                .onDelete { set in
                                    viewModel.tagsToDelete(set, section: section.offset).forEach { tag in
                                        print("(DEBUG) Tag: ", tag)
                                        store.deleteTag(for: tag.objectId)
                                        viewModel.selectedTags.remove(tag)
                                    }
                                }
                            } header: {
                                Text(section.element.initial.uppercased())
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .animation(.easeInOut, value: viewModel.sectionedTags)
                    .environment(\.defaultMinListRowHeight, 66)
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemSymbol: .plus) {
                        viewModel.presentAddTagSheet = true
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("", systemSymbol: .checkmark) {
                        onDismiss(Array(viewModel.selectedTags))
                        dismiss()
                    }
                }
            })
            .task(id: store.tags) {
                self.viewModel.segmentedTags(tags: store.tags)
            }
        }
        .sheet(isPresented: $viewModel.presentAddTagSheet) {
            CreateTagView { name, color in
                let tag = store.createTag(name: name, color: color.asUIColor)
                viewModel.selectedTags.insert(.from(tag))
            }
            .fittedPresentationDetent()
        }
    }
    
    private func listBackground(for index: Int, limit: Int) -> ListButtonBackgroundShape {
        guard limit > 0 else {
            return .unevenRoundedRect(.init(topLeading: 50, bottomLeading: 32, bottomTrailing: 32, topTrailing: 32))
        }
        if index == 0 {
            return .unevenRoundedRect(.init(topLeading: 32, bottomLeading: 0, bottomTrailing: 0, topTrailing: 32))
        } else if index == limit {
            return .unevenRoundedRect(.init(topLeading: 0, bottomLeading: 32, bottomTrailing: 32, topTrailing: 0))
        } else {
            return .rectangle
        }
    }
    
    
    // MARK: - ContentUnavailable
    
    var noTagsView: some View {
        ContentUnavailableView {
            VStack(alignment: .center, spacing: 12) {
                Image(systemSymbol: .tag)
                    .font(.largeTitle)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.proSky.baseColor)
                
                Text("No Tags Available")
                    .font(.title)
                    .foregroundStyle(Color.proSky.foregroundPrimary)
            }
        } description: {
            Text("Add tags and start organizing your reminders")
                .font(.headline)
                .foregroundStyle(Color.proSky.foregroundSecondary)
        } actions: {
            Button("Create Reminder") {
                print("(DEBUG) tapped on tags")
            }
        }
    }
}
