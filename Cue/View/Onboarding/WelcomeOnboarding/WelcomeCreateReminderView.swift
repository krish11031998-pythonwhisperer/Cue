//
//  WelcomeCreateReminderView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/02/2026.
//

import SwiftUI
import VanorUI
import Model

struct WelcomeCreateReminderView: View {
    
    let onAppear: Bool
    @State private var pct: CGFloat = 0
    
    var body: some View {
        GeometryReader { proxy in
            let frame = proxy.frame(in: .global)
            let bubbleStartSize = proxy.size.smallDim - 40
            VStack(alignment: .center, spacing: 12) {
                headerView
                    .padding(.top, proxy.safeAreaInsets.top)
                
                Image(systemSymbol: .checkmarkSealFill)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .symbolEffect(.bounce, options: .repeat(.periodic(1)), isActive: true)
                    .frame(width: 150, height: 150, alignment: .center)
                    .foregroundStyle(Color.proSky.foregroundTertiary)
                    .frame(maxHeight: .infinity, alignment: .center)
                    .visualEffect { content, contentProxy in
                        content
                            .offset(x: 0, y: -(proxy.size.height - contentProxy.size.height).half)
                    }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
//            .background(alignment: .center, content: {
//                ExpandingCircle(startFrame: .init(origin: .init(x: (proxy.size.width - bubbleStartSize).half, y: (proxy.size.height - bubbleStartSize).half), size: .init(squared: bubbleStartSize)),
//                                finalCornerRadius: 0,
//                                pct: pct)
//                .foregroundStyle(Color.proSky.backgroundTertiary)
//                .ignoresSafeArea(edges: .all)
//            })
        }
        .task(id: onAppear) {
            guard onAppear else { return }
            withAnimation(.easeInOut) {
                self.pct = 1
            }
        }
    }
    
    var headerView: some View {
        Text(heroText)
            .multilineTextAlignment(.center)
            .padding(.vertical, 32)
            .containerRelativeFrame(.vertical) { height, _ in
                height * 0.2
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var heroText: AttributedString {
        var attributedString = AttributedString("Let's Create", attributes: .init([.font: UIFont.preferredFont(for: .title1, weight: .semibold), .foregroundColor: Color.proSky.baseColor.asUIColor]))
        let secondAttributedString = AttributedString("your first reminder", attributes: .init([.font: UIFont.preferredFont(forTextStyle: .headline), .foregroundColor: Color.proRed.foregroundPrimary.asUIColor]))
        attributedString.append(AttributedString(stringLiteral: "\n"))
        attributedString.append(secondAttributedString)
        return attributedString
    }
}

#Preview {
    WelcomeCreateReminderView(onAppear: true)
}
