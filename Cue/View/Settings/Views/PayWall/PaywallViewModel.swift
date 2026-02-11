//
//  PaywallViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 11/02/2026.
//

import SwiftUI
import RevenueCat

enum PaywallError: LocalizedError {
    case failedToPurchase
    case failedToRestore
    
    var errorDescription: String? {
        switch self {
        case .failedToPurchase:
            return "Failed to purchase. Please try again."
        case .failedToRestore:
            return "Faild to restore."
        }
    }
}

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
    
    @ObservationIgnored
    var restorePurchaseTask: Task<Void, Never>?
    var restoringPurchase: Bool = false
    
    @ObservationIgnored
    var purchaseTask: Task<Void, Never>?
    
    var showError: Bool = false
    var errorToShow: PaywallError? = nil
    var mustDismiss: Bool = false
    
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
    
    
    // MARK: - Purchase
    
    func purchase(_ purchaseAction: @escaping (StoreProduct) async -> Bool) {
        guard let selectedProduct else { return }
        purchaseTask?.cancel()
        purchaseTask = Task { @MainActor in
            let wasSuccess = await purchaseAction(selectedProduct)
            if wasSuccess {
                mustDismiss = true
            }
        }
    }
    
    
    // MARK: - Restore Purchase
    
    func restorePurchase(_ restorePurchase: @escaping () async -> Result<Bool, Error>) {
        restoringPurchase = true
        restorePurchaseTask = Task {
            let result = await restorePurchase()
            
            guard !Task.isCancelled else { return }
            
            await MainActor.run {
                switch result {
                case .success:
                    mustDismiss = true
                case .failure:
                    showError = true
                    errorToShow = .failedToRestore
                }
            }
        }
    }
}
