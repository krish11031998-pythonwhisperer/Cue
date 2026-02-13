//
//  WelcomeFocusView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/02/2026.
//

import SwiftUI
import VanorUI

struct WelcomeFocusView: View {
 
    let isCurrentTab: Bool
    let completed: () -> Void
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Text(heroText)
                .multilineTextAlignment(.center)
                .padding(.vertical, 32)
                .containerRelativeFrame(.vertical) { height, _ in
                    height * 0.2
                }
                .padding(.horizontal, 16)
            
            Group {
                if isCurrentTab {
                    FocusCountdownView(targetDuration: 3, mode: .forDisplay, theme: Color.proSky) {
                        guard case .completed = $0 else { return }
                        self.completed()
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.horizontal, 20)
                    .visualEffect({ content, proxy in
                        content
                            .offset(x: 0, y: -proxy.size.height * 0.2)
                    })
                    .transition(.blurReplace)
                } else {
                    Color.clear
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .padding(.horizontal, 20)
        .animation(.easeInOut, value: isCurrentTab)
    }
    
    private var heroText: AttributedString {
        var attributedString = AttributedString("Focus with timers", attributes: .init([.font: UIFont.preferredFont(for: .title1, weight: .semibold), .foregroundColor: Color.proSky.baseColor.asUIColor]))
        let secondAttributedString = AttributedString("while completing tasks", attributes: .init([.font: UIFont.preferredFont(forTextStyle: .headline), .foregroundColor: Color.proRed.foregroundPrimary.asUIColor]))
        attributedString.append(AttributedString(stringLiteral: "\n"))
        attributedString.append(secondAttributedString)
        return attributedString
    }
    
}
