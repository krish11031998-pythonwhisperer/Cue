//
//  TagCellView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 12/02/2026.
//

import SwiftUI
import Model
import VanorUI

public struct TagCellView: View {
    
    let tag: TagModel
    let backgroundShape: ListButtonBackgroundShape
    let selected: Bool
    let selectTag: (TagModel) -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var rowColor: Color {
        switch colorScheme {
        case .dark:
            Color.white.opacity(0.05)
        case .light:
            Color.white.opacity(0.25)
        default:
            Color.white.opacity(0.25)
        }
    }
    
    public var body: some View {
        ListButton(backgroundColor: rowColor,
                   shouldHighlight: false,
                   backgroundShape: backgroundShape) {
            selectTag(tag)
        } label: {
            HStack(alignment: .center, spacing: 8) {
                Image(systemSymbol: .tagFill)
                    .foregroundStyle(tag.color)
                    .font(.headline)
                
                Text(tag.name)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if selected {
                    Image(systemSymbol: .checkmark)
                        .font(.headline)
                        .transition(.symbolEffect(.drawOn))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .contentShape(Rectangle())
        }
        .buttonStyle(.automatic)
    }
}
