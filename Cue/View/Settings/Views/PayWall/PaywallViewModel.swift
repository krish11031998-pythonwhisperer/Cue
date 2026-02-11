//
//  PaywallViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 11/02/2026.
//

import SwiftUI
import RevenueCat

@Observable
class PaywallViewModel {
    
    struct PaywallProduct: Identifiable {
        let storeProduct: StoreProduct
        let viewConfig: PayWallProductButton.Model
        
        var id: String {
            storeProduct.productIdentifier
        }
    }
    
    var selectedProduct: StoreProduct? = nil
    var presentProductRoadMap: Bool = false
    var products: [PaywallProduct] = []
    var isCommitingPurchase: Bool = false
    
    
    func updateProducts(_ offering: Offering?) {
        guard let offering else { return }
        var products: [PaywallProduct] = []
        offering.availablePackages.forEach { package in
            
            let title = package.storeProduct.localizedTitle
            let localizedPrice = package.storeProduct.localizedPriceString
            let subscriptionPeriod = package.storeProduct.subscriptionPeriod
            let introductoryDiscount = package.storeProduct.introductoryDiscount
            let localizedPricePerMonth: String?
            
            if package.storeProduct.subscriptionPeriod?.unit == .year {
                localizedPricePerMonth = package.storeProduct.localizedPricePerMonth
            } else {
                localizedPricePerMonth = nil
            }
            
            if let subscriptionPeriod {
                let product = PaywallProduct(storeProduct: package.storeProduct,
                                             viewConfig: .init(productName: title,
                                                               localizedPrice: localizedPrice, localizedPricePerMonth: localizedPricePerMonth, subscriptionPeriod: subscriptionPeriod, introductoryDiscount: introductoryDiscount))
                if subscriptionPeriod.unit == .year {
                    products.insert(product, at: 0)
                    self.selectedProduct = products.first?.storeProduct
                } else {
                    products.append(product)
                }
            }
        }
        
        self.products = products
    }
    
}
