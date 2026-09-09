//
//  CalendarTagsView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/09/2026.
//

import SwiftUI
import Model
import VanorUI

struct CalendarTagsView: View {
    
    @State private var selectedTags: Set<TagModel> = .init()
    let tags: [TagModel]
    let tagSelection: (TagModel) -> Void
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .center, spacing: 4) {
                ForEach(tags) { tag in
                    chipBuilder(isSelected: selectedTags.contains(tag), tag: tag)
                        .fixedSize()
                }
            }
            .padding(.init(top: 6, leading: 6, bottom: 6, trailing: 6))
            .fixedSize(horizontal: false, vertical: true)
        }
        .clipShape(Capsule())
        .glassEffect(.clear, in: .capsule)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    
    // MARK: - TagChipView
    
    @ViewBuilder
    private func chipBuilder(isSelected: Bool, tag: TagModel) -> some View {
        let viewType = TagChipView.ViewType.button(isSelected) {
            if selectedTags.contains(tag) {
                self.selectedTags.remove(tag)
            } else {
                self.selectedTags.insert(tag)
            }
            tagSelection(tag)
        }
        
        TagChipView(model: .init(name: tag.name, color: tag.color, viewType: viewType))
    }
}
