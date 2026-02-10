//
//  WelcomeHabitView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/02/2026.
//
//
import VanorUI
import SwiftUI

struct WelcomeHabitView: View {
    
    let onAppear: Bool
    let longPressAction: Callback
    @State private var showHabitBubble: Bool = false
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            Text(heroText)
                .multilineTextAlignment(.center)
                .padding(.vertical, 32)
                .containerRelativeFrame(.vertical) { height, _ in
                    height * 0.2
                }
                .padding(.horizontal, 16)
            if onAppear {
                HabitBubble(model: .init(habitName: "Long press to log a habit", habitIcon: "target", habitReminder: Date.now, theme: Color.proSky, longPressGesture: longPressAction))
                    .aspectRatio(1, contentMode: .fit)
                    .padding(.horizontal, 0)
                    .visualEffect({ content, proxy in
                        content
                            .offset(x: 0, y: -proxy.size.height * 0.2)
                    })
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)                
            }
        }
        .padding(.horizontal, 20)
        .task(id: onAppear) {
            guard onAppear else { return }
            withAnimation(.easeInOut) {
                self.showHabitBubble = true
            }
        }
    }
    
    private var heroText: AttributedString {
        var attributedString = AttributedString("Log Habits", attributes: .init([.font: UIFont.preferredFont(for: .title1, weight: .semibold), .foregroundColor: Color.proSky.baseColor.asUIColor]))
        let secondAttributedString = AttributedString("and achieve your goals", attributes: .init([.font: UIFont.preferredFont(forTextStyle: .headline), .foregroundColor: Color.proRed.foregroundPrimary.asUIColor]))
        attributedString.append(AttributedString(stringLiteral: "\n"))
        attributedString.append(secondAttributedString)
        return attributedString
    }
}


#Preview {
    WelcomeHabitView(onAppear: true) {
        print("(DEBUG) longPressed!")
    }
}
