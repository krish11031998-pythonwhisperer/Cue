//
//  SubscriptionManager.swift
//  Cue
//
//  Created by Krishna Venkatramani on 11/02/2026.
//

import RevenueCat
import Foundation

@Observable
@MainActor final class SubscriptionManager {
    
    struct Constants {

        /*
         The API key for your app from the RevenueCat dashboard: https://app.revenuecat.com
         */
        static let apiKey = "appl_FVFdAZwKNeqbZOGtMtaoaVrUVAW"

        /*
         The entitlement identifier from the RevenueCat dashboard that is activated upon successful in-app purchase for the duration of the purchase.
         */
        static let entitlementIdentifier: String? = "cue:it Pro"
    }
    
    var customerInfo: CustomerInfo? {
        didSet {
            guard let entitlementIdentifier = Constants.entitlementIdentifier else { return }
            subscriptionActive = customerInfo?.entitlements[entitlementIdentifier]?.isActive == true
        }
    }
    
    var userIsPro: Bool {
        #if DEBUG
        return true
        #else
        guard let customerInfo else { return false }
        return customerInfo.entitlements["cue:it Pro"]?.isActive == true
        #endif
    }
    
    /* The latest offerings */
    var offerings: Offerings?

    /* Checks if a subscription is active for a given entitlement */
    var subscriptionActive: Bool = false

    var isFetchingOfferings: Bool = false

    var isPurchasing: Bool = false
    
    init() {
        // Configure the SDK with the API Key
        Purchases.configure(withAPIKey: Constants.apiKey)
        /* Listen to changes in the `customerInfo` object using an `AsyncStream` */
        Task {
            for await newCustomerInfo in Purchases.shared.customerInfoStream {
                await MainActor.run { customerInfo = newCustomerInfo }
            }
        }
    }

    func purchase(_ product: StoreProduct) async -> Bool {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let (_, customerInfo, userCancelled) = try await Purchases.shared.purchase(product: product)

            guard !userCancelled else { return false }

            self.customerInfo = customerInfo
            
            return true
        } catch {
            print("Failed to purchase product with error: \(error)")
        }
        
        return false
    }
    
    func purchase(_ package: Package) async {
        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let (_, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package)

            guard !userCancelled else { return }

            self.customerInfo = customerInfo
        } catch {
            print("Failed to purchase package with error: \(error)")
        }
    }
    
    func fetchOfferings() async {
        isFetchingOfferings = true
        do {
            offerings = try await Purchases.shared.offerings()
        } catch {
            print(error)
        }
        isFetchingOfferings = false
    }
    
    func restorePurchase() async -> Result<Bool, Error> {
        do {
            let _ = try await Purchases.shared.restorePurchases()
            return .success(true)
        } catch {
            return .failure(error)
        }
    }
    
    func fetchStoreProducts(withIdentifiers productIdentifiers: [String]) async -> [StoreProduct] {
        await Purchases.shared.products(productIdentifiers)
    }
    
    func checkIfUserIsEligibleForFreeTrial(_ package: [Package]) async -> [Package : IntroEligibility] {
        await Purchases.shared.checkTrialOrIntroDiscountEligibility(packages: package)
    }
    
    func checkIfUserIsEligibleForFreeTrial(_ product: StoreProduct) async -> Bool {
        let result = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: product)
        switch result {
        case .unknown:
            return false
        case .ineligible:
            return false
        case .eligible:
            return true
        case .noIntroOfferExists:
            return false
        }
    }
}
