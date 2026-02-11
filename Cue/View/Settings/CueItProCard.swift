//
//  CueItProCard.swift
//  Cue
//
//  Created by Krishna Venkatramani on 10/02/2026.
//

import SwiftUI
import VanorUI

struct CueItProCard: View {
    let userIsPro: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cue:it Pro")
                .font(.title)
                .fontWeight(.semibold)
            Group {
                if userIsPro {
                    Text("Manage your subscription")
                } else {
                    Text("Start your free trial")
                }
            }
            .fontWeight(.medium)
        }
        .foregroundStyle(Color.proSky.foregroundTertiary)
        .padding(.init(top: 24, leading: 16, bottom: 24, trailing: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .center) {
            if userIsPro {
                MeshGradient(width: 2, height: 2, points: [
                    [0, 0], [1, 0],
                    [0, 1], [1, 1]
                ], colors: [Color.proSky.outlinePrimary, Color.proSky.outlineSecondary, Color.proSky.outlineTertiary, Color.proSky.baseColor])
            } else {
                MeshGradient(width: 2, height: 2, points: [
                    [0, 0], [1, 0],
                    [0, 1], [1, 1]
                ], colors: [Color.proSky.backgroundPrimary, Color.proSky.backgroundSecondary, Color.proSky.backgroundTertiary, Color.proSky.surfacePrimary])
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 32))
    }
}

#Preview {
    VStack {
        CueItProCard(userIsPro: false)
        CueItProCard(userIsPro: true)
    }
    .padding(.horizontal, 20)
}
