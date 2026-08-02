//
//  ReminderTagView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 26/07/2026.
//

import SwiftUI
import VanorUI
import Model
import CoreData

struct ReminderTagView: View {
    
    @Environment(\.theme) var theme
    let tags: [TagModel]
    let presentTags: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if tags.isEmpty {
                Button(action: presentTags) {
                    Label("add a tag", systemSymbol: .plus)
                        .font(.bitcountRegular(style: .body))
                        .labelStyle(IconAndTitleLabelStyle())
                        .frame(minHeight: 28, alignment: .center)
                }
                .tint(theme.baseColor)
                .buttonStyle(.glassProminent)
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                OverFlowingHorizontalLayout(horizontalSpacing: 8, verticalSpacing: 8) {
                    ForEach(tags) { tag in
                        TagChipView(model: .init(name: tag.name, color: tag.color, viewType: .view))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Button(action: presentTags) {
                        Image(systemSymbol: .plus)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(theme.foregroundSecondary)
                            .padding(4)
                            .glassEffect(.regular.tint(theme.backgroundSecondary), in: .circle)
                    }
                }
            }
        }
        .padding(.all, 15)
        .modifier(RowBackground())
        .clipShape(.roundedRect(cornerRadius: 26))
    }
}


#Preview {
    ZStack(alignment: .center) {
        Color.cueItBackground
        ReminderTagView(tags: [.init(id: NSManagedObject().objectID, name: "Fitness", color: Color.aqua), .init(id: NSManagedObject().objectID, name: "Mindfullness", color: Color.perwinkle)]) { }
            .padding(.horizontal, 20)
    }
}
