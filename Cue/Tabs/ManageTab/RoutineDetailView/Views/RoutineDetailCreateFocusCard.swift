//
//  RoutineDetailCreateFocusCard.swift
//  Cue
//
//  Created by Krishna Venkatramani on 27/09/2026.
//

import SwiftUI
import VanorUI
import Model

struct RoutineDetailCreateFocusCard: View {
    
    @Environment(\.theme) var theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label {
                Text("Add Focus Session")
            } icon: {
                Image(systemSymbol: .plus)
            }
            .font(.headline)
            .foregroundStyle(theme.foregroundPrimary)
            Text("Create Focus Session to help your routines stick")
                .font(.footnote.weight(.medium))
                .foregroundStyle(theme.foregroundSecondary)
        }
        .padding(.all, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .center) {
            RoundedRectangle(cornerRadius: 32)
                .fill(theme.backgroundPrimary)
                .stroke(theme.outlinePrimary, style: .init(lineWidth: 1, lineCap: .round, lineJoin: .round, dash: [2, 5], dashPhase: 0.4))
        }
    }
}

#Preview {
    RoutineDetailCreateFocusCard()
        .padding(.horizontal, 16)
}
