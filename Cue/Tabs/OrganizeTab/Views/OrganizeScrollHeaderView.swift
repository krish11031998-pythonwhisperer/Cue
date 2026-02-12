//
//  OrganizeScrollHeaderView.swift
//  Model
//
//  Created by Krishna Venkatramani on 12/02/2026.
//

import Foundation
import SwiftUI
import VanorUI

struct OrganizeScrollHeaderView: View {
    
    let chipViewModels: [TagChipView.Model]
    
    var body: some View {
        ScrollView(.horizontal) {
            HStack(alignment: .center, spacing: 8) {
                ForEach(chipViewModels.indices, id: \.self) { idx in
                    let tag = chipViewModels[idx]
                    TagChipView(model: tag)
                }
            }
            .padding(.horizontal, 20)
        }
        .scrollIndicators(.hidden, axes: .horizontal)
    }
    
}
