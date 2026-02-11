//
//  WelcomeAlarmAndNotificationView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 10/02/2026.
//

import SwiftUI
import VanorUI
import Model

struct WelcomeAlarmAndNotificationView: View {
    @Environment(Store.self) var store
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Text(heroText)
                .multilineTextAlignment(.center)
                .padding(.top, 32)
                .containerRelativeFrame(.vertical) { height, _ in
                    height * 0.2
                }
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, alignment: .center)
            
            VStack(alignment: .center, spacing: 56) {
                Image(systemSymbol: .bellFill)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120, alignment: .center)
                    .foregroundStyle(Color.proSky.baseColor)
                    .symbolEffect(.wiggle, options: .repeat(.periodic(3, delay: nil)), isActive: true)
                
                Button {
                    store.notificationManager.requestForAuthorizationAfterCheckingNotificationSettings()
                } label: {
                    Text("Enable Notifications")
                        .font(.headline)
                        .padding(.init(top: 8, leading: 12, bottom: 8, trailing: 12))
                }
                .tint(Color.proSky.outlinePrimary)
                .buttonStyle(.glassProminent)

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .visualEffect { content, proxy in
                content
                    .offset(x: 0, y: -(proxy.size.height/0.8 - 12) * 0.1)
            }
        }
        .padding(.horizontal, 20)
    }
    
    
    private var heroText: AttributedString {
        var attributedString = AttributedString("Want a little nudge when it matters? ", attributes: .init([.font: UIFont.preferredFont(for: .title1, weight: .semibold), .foregroundColor: Color.proSky.baseColor.asUIColor]))
        let secondAttributedString = AttributedString("Enable notifications", attributes: .init([.font: UIFont.preferredFont(forTextStyle: .headline), .foregroundColor: Color.proRed.foregroundPrimary.asUIColor]))
        attributedString.append(AttributedString(stringLiteral: "\n"))
        attributedString.append(secondAttributedString)
        return attributedString
    }
    
}


#Preview {
    WelcomeAlarmAndNotificationView()
}
