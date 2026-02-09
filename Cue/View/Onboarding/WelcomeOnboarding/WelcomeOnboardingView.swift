//
//  WelcomeOnboardingView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/02/2026.
//

import SwiftUI
import VanorUI

struct WelcomeOnboardingView: View {
    
    
    var themeColor: Color {
        Color.proSky.baseColor
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Text(heroText)
                .multilineTextAlignment(.center)
                .padding(.vertical, 32)
                .containerRelativeFrame(.vertical) { height, _ in
                    height * 0.2
                }
            VStack(alignment: .center, spacing: -6) {
                ForEach(WelcomeItemComponents.allCases.enumerated(), id: \.element) { itemContent in
                    WelcomeFeatureItemView(cardCorner: itemContent.offset % 2 == 0 ? .leading : .trailing, component: itemContent.element)
                        .zIndex(Double(itemContent.offset))
                        .dynamicTypeSize(..<DynamicTypeSize.large)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .visualEffect { content, proxy in
                content
                    .offset(x: 0, y: -proxy.size.height * 0.1)
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    
    
    private var heroText: AttributedString {
        var attributedString = AttributedString("Create impactful reminders", attributes: .init([.font: UIFont.preferredFont(for: .title1, weight: .semibold), .foregroundColor: Color.proSky.baseColor.asUIColor]))
        let secondAttributedString = AttributedString("and plan out your day effectively", attributes: .init([.font: UIFont.preferredFont(forTextStyle: .headline), .foregroundColor: Color.proRed.foregroundPrimary.asUIColor]))
        attributedString.append(AttributedString(stringLiteral: "\n"))
        attributedString.append(secondAttributedString)
        return attributedString
    }
}


#Preview {
    WelcomeOnboardingView()
}
