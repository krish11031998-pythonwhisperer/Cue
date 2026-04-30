//
//  FocusTabBottomAccessoryView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 30/04/2026.
//

import SwiftUI
import VanorUI

public struct FocusTabBottomAccessoryView: View {
    
    @Environment(\.tabViewBottomAccessoryPlacement) var tabBarPlacement
 
    var theme: LCHColor {
        Color.proSky
    }
    
    public var body: some View {
        switch tabBarPlacement {
        case .expanded:
            Text("Start Timer")
                .font(.bitcountMedium(style: .headline))
                .foregroundStyle(theme.foregroundPrimary)
                .padding(.init(top: 12, leading: 14, bottom: 12, trailing: 14))
                .frame(maxWidth: .infinity, alignment: .center)
                .background(alignment: .center) {
                    LinearGradient(colors: [theme.surfaceTertiary, theme.surfacePrimary], startPoint: .top, endPoint: .bottom)
                        .clipShape(Capsule())
                    Capsule()
                        .fill(Color.clear)
                        .stroke(theme.outlinePrimary, style: .init(lineWidth: 2))
                }
                .contentShape(Capsule())
                .onTapGesture {
                    print("(DEBUG) tapped on timer")
                }
        @unknown default:
            HStack(alignment: .center, spacing: 8) {
                Text("Start Timer")
//                    .font(.bitcountMedium(style: .title3))
                    .font(.headline)
                    .foregroundStyle(theme.foregroundPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .background(alignment: .center) {
                        LinearGradient(colors: [theme.surfaceTertiary, theme.surfacePrimary], startPoint: .top, endPoint: .bottom)
                    }
                    .contentShape(Capsule())
                    .onTapGesture {
                        print("(DEBUG) tapped on startTimer")
                    }
            }
        }
    }
}
