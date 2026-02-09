//
//  WelcomeFeatureItem.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/02/2026.
//

import VanorUI
import SwiftUI

public struct WelcomeFeatureItemView: View {
    public enum CardCorner {
        case leading
        case trailing
        
        var edge: Edge {
            switch self {
            case .leading:
                return .leading
            case .trailing:
                return .trailing
            }
        }
    }
    
    private let cardCorner: CardCorner
    private let icon: Icon
    private let buttonName: String
    private let color: Color
    private let angleDegrees: CGFloat
    @State private var showButton: Bool = false
    
    public init(cardCorner: CardCorner = .leading, component: WelcomeItemComponents) {
        self.init(cardCorner: cardCorner, cardImageResource: component.icon, buttonName: component.title, color: component.color.baseColor, angleDegrees: component.rotationAngle)
    }
    
    public init(cardCorner: CardCorner = .leading, cardImageResource: Icon, buttonName: String, color: Color, angleDegrees: CGFloat) {
        self.cardCorner = cardCorner
        self.icon = cardImageResource
        self.buttonName = buttonName
        self.color = color
        self.angleDegrees = angleDegrees
    }
    
    public var body: some View {
        buttonLabel
            .popInContainer(angle: angleDegrees)
    }
    
    private var theme: LCHColor {
        .init(color: color)
    }
    
    // MARK: - ViewBuilders
    
    private var buttonLabel: some View {
        HStack(alignment: .center, spacing: 8) {
            if cardCorner == .leading {
                ReminderIconView(icon: icon, foregroundColor: theme.foregroundSecondary, backgroundColor: .clear, font: .largeTitle)
                    .fixedSize()
            }
            
            Text(buttonName)
                .font(.headline)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .foregroundStyle(theme.foregroundSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if cardCorner == .trailing {
                ReminderIconView(icon: icon, foregroundColor: theme.foregroundSecondary, backgroundColor: .clear, font: .largeTitle)
                    .fixedSize()
            }
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.init(top: 14, leading: 14, bottom: 14, trailing: 14))
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(theme.backgroundPrimary, in: .cardCornerShape(edge: cardCorner.edge))
        .background(theme.outlinePrimary, in: .cardCornerShape(edge: cardCorner.edge).stroke(lineWidth: 2))
    }
    
    
    // MARK: - Helpers
    
    private var animation: SwiftUI.Animation {
        .snappy(duration: 0.5, extraBounce: 0.1)
    }
    
    private var borderColor: Color {
        .init("#242124")
    }
    
}

#Preview {
    WelcomeFeatureItemView(cardCorner: .leading, component: WelcomeItemComponents.useAI)
    .padding(.horizontal, 24)
    WelcomeFeatureItemView(cardCorner: .trailing, component: WelcomeItemComponents.alarms)
    .padding(.horizontal, 24)
    WelcomeFeatureItemView(cardCorner: .leading, component: WelcomeItemComponents.habits)
    .padding(.horizontal, 24)
}
