//
//  SubscriptionManager.swift
//  Cue
//
//  Created by Krishna Venkatramani on 11/02/2026.
//

import RevenueCat
import Foundation
import Model

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
    
    /// Owns the persisted pro status. This manager only ever *writes* the entitlement to it —
    /// read the user's pro status from `store.isProUser`, which survives launches and works
    /// offline, rather than from `customerInfo`, which is `nil` until RevenueCat answers.
    @ObservationIgnored
    let store: Store
    
    var customerInfo: CustomerInfo? {
        didSet { persistProStatus(from: customerInfo) }
    }
    
    /* The latest offerings */
    var offerings: Offerings?

    var isFetchingOfferings: Bool = false

    var isPurchasing: Bool = false
    
    init(store: Store) {
        self.store = store
        // Configure the SDK with the API Key
        Purchases.configure(withAPIKey: Constants.apiKey)
        /* Listen to changes in the `customerInfo` object using an `AsyncStream` */
        Task {
            for await newCustomerInfo in Purchases.shared.customerInfoStream {
                await MainActor.run { customerInfo = newCustomerInfo }
            }
        }
    }
    
    
    // MARK: - Persisting the entitlement
    
    /// Writes the entitlement RevenueCat just reported through to `Store`, which persists it on
    /// the `User` and publishes the change.
    ///
    /// A `nil` `customerInfo` means "no answer yet", never "not subscribed", so it leaves the
    /// persisted status alone — otherwise a launch would downgrade a paying user to free before
    /// the SDK had a chance to reply.
    private func persistProStatus(from customerInfo: CustomerInfo?) {
        guard let customerInfo,
              let entitlementIdentifier = Constants.entitlementIdentifier
        else { return }
        
        let entitlement = customerInfo.entitlements[entitlementIdentifier]
        
        guard entitlement?.isActive == true else {
            return store.updateProStatus(.free)
        }
        
        // A lifetime or non-renewing entitlement has no expiration date; `nil` there means
        // "does not lapse", which is exactly how `UserProStatus` reads it.
        store.updateProStatus(.pro, expiryDate: entitlement?.expirationDate)
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
    
    /// `.success(true)` means an active entitlement was actually restored —
    /// a non-throwing restore with nothing to restore returns `.success(false)`.
    func restorePurchase() async -> Result<Bool, Error> {
        do {
            // Assigning `customerInfo` rather than waiting on `customerInfoStream` also
            // persists the restored entitlement the moment we know about it.
            let restoredInfo = try await Purchases.shared.restorePurchases()
            self.customerInfo = restoredInfo
            guard let entitlementIdentifier = Constants.entitlementIdentifier else { return .success(false) }
            return .success(restoredInfo.entitlements[entitlementIdentifier]?.isActive == true)
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
    
    /// Runs `action` for a pro user, otherwise asks the nearest `paywallPresentation()` to show
    /// the paywall.
    ///
    /// `isProFeature` lets a call site gate only some of its cases — a timer-type picker gates
    /// pomodoro but must still let the user pick classic, for example.
    func proUserAction(isProFeature: Bool = true, _ action: @escaping () -> Void) {
        guard isProFeature, !store.isProUser else { return action() }
        NotificationCenter.default.post(name: .presentPaywall, object: nil)
    }
}
