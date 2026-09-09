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
    
    let tags: [TagModel]
    let tagSelection: (TagModel) -> Void
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .center, spacing: 4) {
                ForEach(tags) { tag in
                    chipBuilder(isSelected: false, tag: tag)
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
            tagSelection(tag)
        }
        
        TagChipView(model: .init(name: tag.name, color: tag.color, viewType: viewType))
    }
}
