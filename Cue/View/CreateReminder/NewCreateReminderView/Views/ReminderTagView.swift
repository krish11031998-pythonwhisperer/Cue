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
                VStack(alignment: .leading, spacing: 16) {
                    Text("Start adding some tags")
                        .font(.bitcountMedium(style: .headline))
                        .frame(maxWidth: .infinity, alignment: .center)
                    Button(action: presentTags) {
                        Label("Add a Tag", systemSymbol: .plus)
                            .labelStyle(IconAndTitleLabelStyle())
                            .frame(maxWidth: .infinity, minHeight: 28, alignment: .center)
                    }
                    .font(.headline)
                    .tint(theme.baseColor)
                    .buttonStyle(.glassProminent)
                }
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
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.25), in: .roundedRect(cornerRadius: 26))
    }
}


#Preview {
    ZStack(alignment: .center) {
        Color.cueItBackground
        ReminderTagView(tags: [.init(id: NSManagedObject().objectID, name: "Fitness", color: Color.aqua), .init(id: NSManagedObject().objectID, name: "Mindfullness", color: Color.perwinkle)]) { }
            .padding(.horizontal, 20)
    }
}
