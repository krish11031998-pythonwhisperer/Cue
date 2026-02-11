//
//  PayWallProductButton.swift
//  Cue
//
//  Created by Krishna Venkatramani on 11/02/2026.
//

import SwiftUI
import VanorUI
import RevenueCat

struct PeekoverTransform: GeometryEffect {
    
    var show: CGFloat
    let additionalY: CGFloat
    
    var animatableData: CGFloat {
        get { show }
        set { show = newValue }
    }
    
    init(show: CGFloat, additionalY: CGFloat) {
        self.show = show
        self.additionalY = additionalY
    }
    
    func effectValue(size: CGSize) -> ProjectionTransform {
        print("(DEBUG) size.height:", size.height)
        let transform = CGAffineTransform(translationX: 0, y: (-size.height + additionalY) * show)
        return .init(transform)
    }
}

struct PeekoverModifier: ViewModifier {
    let show: Bool
    let additionalY: CGFloat
    
    func body(content: Content) -> some View {
        content
            .modifier(PeekoverTransform(show: show ? 1 : 0, additionalY: additionalY))
    }
}

//struct PeekoverTransition: Transition {
//    
//}
extension AnyTransition {
    static func peekover(additionalY: CGFloat = 0) -> AnyTransition {
        .modifier(active: PeekoverModifier(show: false, additionalY: additionalY), identity: PeekoverModifier(show: true, additionalY: additionalY))
    }
}

struct PayWallProductButton: View {
    
    struct Model: Hashable {
        let productName: String
        let localizedPrice: String
        let localizedPricePerMonth: String?
        let subscriptionPeriod: SubscriptionPeriod
        let introductoryDiscount: StoreProductDiscount?
    }
    
    let model: Model
    let isSelected: Bool
    let action: () -> Void
    
    init(model: Model, isSelected: Bool, action: @escaping () -> Void) {
        self.model = model
        self.isSelected = isSelected
        self.action = action
    }
    
    private let currencyNumberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .currency
        numberFormatter.locale = .current
        return numberFormatter
    }()
    
    var isYearlyProduct: Bool {
        guard case .year = model.subscriptionPeriod.unit else {
            return false
        }
        
        return true
    }
    
    var hasTrial: Bool {
        guard let introductoryDiscount = model.introductoryDiscount else {
            return false
        }
        
        return introductoryDiscount.paymentMode == .freeTrial
    }
    
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(model.productName)
                .font(.body)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundStyle(isSelected ? Color.proSky.foregroundSecondary : Color.text)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(model.localizedPrice)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? Color.proSky.foregroundSecondary : Color.text)
                
                if isYearlyProduct, let localizedPricePerMonth = model.localizedPricePerMonth {
                    Text("\(localizedPricePerMonth) / mo")
                        .font(.caption2)
                        .fontWeight(isSelected ? .semibold : .regular)
                        .foregroundStyle(isSelected ? Color.proSky.foregroundTertiary : Color.secondaryText)
                } else {
                    EmptyView()
                }
            }
        }
        .padding(.init(top: 16, leading: 20, bottom: 16, trailing: 20))
        .containerShape(RoundedRectangle(cornerRadius: 18))
        .frame(minHeight: 70)
        .padding(.all, 1)
        .background(isSelected ? Color.proSky.backgroundPrimary : Color.secondarySystemGroupedBackground, in: .roundedRect(cornerRadius: 18))
        .overlay(alignment: .center) {
            if isSelected {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.clear)
                    .stroke(Color.proSky.baseColor, style: .init(lineWidth: 2, lineCap: .butt))
            }
        }
        .animation(.default, value: isSelected)
        .background(alignment: .top, content: {
            if isSelected && hasTrial {
                Text("7-day free trial")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.proSky.invertedForegroundPrimary)
                    .padding(.init(top: 8, leading: 16, bottom: 24, trailing: 16))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(Color.proSky.baseColor, in: UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 18, style: .continuous))
                    .transition(.peekover(additionalY: 18).animation(.snappy(duration: 0.25)))
            }
        })
        .onTapGesture {
            print("(DEBUG) tpping")
            action()
        }
    }
}
