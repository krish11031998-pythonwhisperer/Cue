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
    
    public var body: some View {
        ListButton(backgroundColor: .systemBackground,
                   shouldHighlight: false,
                   backgroundShape: backgroundShape) {
            selectTag(tag)
        } label: {
            HStack(alignment: .center, spacing: 8) {
                Circle()
                    .fill(tag.color)
                    .frame(width: 24, height: 24, alignment: .center)
                
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
