//
//  PayWallProductButton.swift
//  Cue
//
//  Created by Krishna Venkatramani on 11/02/2026.
//

import SwiftUI
import VanorUI
import RevenueCat

struct PayWallProductButton: View {
    
    struct Model: Hashable {
        let productName: String
        let localizedPrice: String
        let localizedPricePerMonth: String?
        let subscriptionPeriod: SubscriptionPeriod
        let introductoryDiscount: StoreProductDiscount?
    }
    
    @Environment(\.colorScheme) var colorScheme
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
    
    /// How long one subscription period lasts, e.g. "1 month" or "1 year".
    ///
    /// Guideline 3.1.2(c) requires the length of the subscription to be stated in the purchase
    /// flow itself. The product's display name from App Store Connect is not enough — this is
    /// rendered under it on every plan, selected or not.
    var subscriptionLengthLabel: String {
        Self.durationLabel(value: model.subscriptionPeriod.value,
                           unit: model.subscriptionPeriod.unit)
    }
    
    /// The intro offer written out, e.g. "Includes 1-week free trial".
    ///
    /// `nil` for plans with no free trial, which renders nothing.
    var trialLabel: String? {
        guard let introductoryDiscount = model.introductoryDiscount,
              introductoryDiscount.paymentMode == .freeTrial else {
            return nil
        }

        let period = introductoryDiscount.subscriptionPeriod
        return "Includes \(Self.durationLabel(value: period.value, unit: period.unit)) free trial"
    }
    
    /// The badge that peeks over the selected card. Shorter than `trialLabel` because it sits in
    /// a narrow pill.
    var trialBadge: String? {
        guard let introductoryDiscount = model.introductoryDiscount,
              introductoryDiscount.paymentMode == .freeTrial else {
            return nil
        }

        let period = introductoryDiscount.subscriptionPeriod
        return "\(Self.durationLabel(value: period.value, unit: period.unit)) free trial"
    }
    
    private static func durationLabel(value: Int, unit: SubscriptionPeriod.Unit) -> String {
        let unitName: String
        switch unit {
        case .day:   unitName = "day"
        case .week:  unitName = "week"
        case .month: unitName = "month"
        case .year:  unitName = "year"
        }
        
        return "\(value) \(unitName)\(value == 1 ? "" : "s")"
    }
    
    private var secondaryForeground: Color {
        isSelected ? Color.proSky.foregroundTertiary : Color.secondaryText
    }
    
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 3) {
                Text(model.productName)
                    .font(.body)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundStyle(isSelected ? Color.proSky.foregroundSecondary : Color.text)
                
                Text(subscriptionLengthLabel)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(secondaryForeground)
                
                if let trialLabel {
                    Text(trialLabel)
                        .font(.caption2)
                        .foregroundStyle(secondaryForeground)
                }
            }
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
                        .foregroundStyle(secondaryForeground)
                } else {
                    EmptyView()
                }
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.init(top: 16, leading: 20, bottom: 16, trailing: 20))
        .containerShape(RoundedRectangle(cornerRadius: 18))
        .frame(minHeight: 70)
        .padding(.all, 1)
        .background(isSelected ? Color.proSky.backgroundPrimary : colorScheme == .light ? Color.tertiarySystemGroupedBackground : Color.secondarySystemGroupedBackground, in: .roundedRect(cornerRadius: 18))
        .overlay(alignment: .center) {
            if isSelected {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.clear)
                    .stroke(Color.proSky.baseColor, style: .init(lineWidth: 2, lineCap: .butt))
            }
        }
        .animation(.default, value: isSelected)
        .background(alignment: .top, content: {
            if isSelected, let trialBadge {
                Text(trialBadge)
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
            action()
        }
    }
}
