//
//  CreaterReminderSectionHeader.swift
//  Cue
//
//  Created by Krishna Venkatramani on 20/01/2026.
//

import SwiftUI
import VanorUI

struct IconAndTitleLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 4) {
            configuration.icon
            configuration.title
        }
    }
}

extension LabelStyle where Self == IconAndTitleLabelStyle {
    static var iconAndTitle: IconAndTitleLabelStyle {
        IconAndTitleLabelStyle()
    }
}

struct CreateReminderSectionHeaderView: View {
    
    let canLoadSuggestions: Bool
    let isLoadingSuggestions: Bool
    let action: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text("Add Tasks")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Button(action: action) {
                Group {
                    if isLoadingSuggestions {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(Color.proSky.foregroundPrimary)
                    } else {
                        Label("Suggest Tasks", systemSymbol: .sparkles)
                            .font(.caption2)
                            .labelStyle(.iconAndTitle)
                    }
                }
                .transition(.opacity)
                .animation(.default, value: isLoadingSuggestions)
                .padding(.init(top: 2, leading: 4, bottom: 2, trailing: 4))
                .clipped()
            }
            .tint(Color.proSky.baseColor)
            .buttonStyle(.glassProminent)
            .disabled(!canLoadSuggestions)
        }
    }
}

#Preview {
    @Previewable @State var isLoadingSuggestion: Bool = false
    CreateReminderSectionHeaderView(canLoadSuggestions: true, isLoadingSuggestions: isLoadingSuggestion) {
        Task { @MainActor in
            isLoadingSuggestion = true
            try? await Task.sleep(for: .milliseconds(1350))
            isLoadingSuggestion = false
            
        }
    }
    .animation(.default, value: isLoadingSuggestion)
    .padding(.horizontal, 20)
}
