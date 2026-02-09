//
//  WelcomeFocusView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/02/2026.
//

import SwiftUI
import VanorUI

struct WelcomeFocusView: View {
 
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Text(heroText)
                .multilineTextAlignment(.center)
                .padding(.vertical, 32)
                .containerRelativeFrame(.vertical) { height, _ in
                    height * 0.2
                }
                .padding(.horizontal, 16)
            
            FocusCountdownView(targetDuration: 5, theme: Color.proSky)
                .aspectRatio(1, contentMode: .fit)
                .padding(.horizontal, 32)
                .visualEffect({ content, proxy in
                    content
                        .offset(x: 0, y: -proxy.size.height * 0.2)
                })
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }
    
    private var heroText: AttributedString {
        var attributedString = AttributedString("Focus", attributes: .init([.font: UIFont.preferredFont(for: .title1, weight: .semibold), .foregroundColor: Color.proSky.baseColor.asUIColor]))
        let secondAttributedString = AttributedString("while completing tasks", attributes: .init([.font: UIFont.preferredFont(forTextStyle: .headline), .foregroundColor: Color.proRed.foregroundPrimary.asUIColor]))
        attributedString.append(AttributedString(stringLiteral: "\n"))
        attributedString.append(secondAttributedString)
        return attributedString
    }
    
}
