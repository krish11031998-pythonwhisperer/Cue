//
//  CueAppBlockManager.swift
//  Model
//
//  Created by Krishna Venkatramani on 10/08/2026.
//

import Foundation
import FamilyControls
import ManagedSettings

@MainActor
class CueAppBlockManager: FocusAppShieldCoordinator {

    enum Error: LocalizedError, Swift.Error {
        case deniedAccess
        case unknownStatus(AuthorizationStatus)
        
        var errorDescription: String? {
            switch self {
            case .deniedAccess:
                return "Denied access for using Family Sharing APIs to block apps"
            case .unknownStatus(let status):
                return "Unknown Authorization State: \(status.description)"
            }
        }
    }
    
    private(set) var authorizationStatus: AuthorizationStatus = .notDetermined

    private let authorizationCenter = AuthorizationCenter.shared
    
    private(set) var currentAppBlockIsRunning: Bool = false
    
    // MARK: Private Properties
    
    private static let nameIdentifier = "com.Krishna.cue-it"
    // A data store that stores settings to the current user or device.
    private let managedSettingsStore: ManagedSettingsStore =
        ManagedSettingsStore(named: .init(nameIdentifier))

    private static let userDefaults: UserDefaults =
        UserDefaults(suiteName: "group.krishna.cue-it")
        ?? .standard
    
    nonisolated static let sheildConfigurationKey: String = "currentShieldConfiguration"
    
    static func retrieveAuthorization() async throws -> AuthorizationStatus {
        let authorizationCenter = AuthorizationCenter.shared
        let authorizationStatus = authorizationCenter.authorizationStatus
        guard authorizationStatus != .approved else { return authorizationStatus }
        
        switch authorizationStatus {
        case .notDetermined:
            if await requestAuthorization() {
                return authorizationStatus
            } else {
                throw Error.deniedAccess
            }
        case .denied:
            throw Error.deniedAccess
        case .approved, .approvedWithDataAccess:
            return .approved
        @unknown default:
            throw Error.unknownStatus(authorizationStatus)
        }
    }

    @discardableResult
    static func requestAuthorization() async -> Bool {
        let authorizationCenter = AuthorizationCenter.shared
        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            return authorizationCenter.authorizationStatus == .approved
        } catch {
            print("(ERROR) app block authorization request failed: ", error.localizedDescription)
            return false
        }
    }

    static func revokeAuthorization() async {
        let authorizationCenter = AuthorizationCenter.shared
        do {
            let _ = try await withCheckedThrowingContinuation { continuation in
                authorizationCenter.revokeAuthorization { result in
                    switch result {
                    case .success:
                        continuation.resume(returning: ())
                    case .failure(let failure):
                        continuation.resume(throwing: failure)
                    }
                }
            }
        } catch {
            print("(ERROR) app block authorization revoke failed: ", error.localizedDescription)
        }
    }
    
    
    // MARK: - Restrictions
    
    func applyRestrictions(_ selection: FamilyActivitySelection) {
        applyImmediateRestrictions(applicationTokens: selection.applicationTokens,
                                   categoryTokens: selection.categoryTokens,
                                   webDomainTokens: selection.webDomainTokens)
    }
    
    func applyImmediateRestrictions(
        applicationTokens: Set<ApplicationToken>,
        categoryTokens: Set<ActivityCategoryToken>,
        webDomainTokens: Set<WebDomainToken>
    ) {
        managedSettingsStore.shield.applications = applicationTokens
        managedSettingsStore.shield.categories = categoryTokens
        managedSettingsStore.shield.webDomains = webDomainTokens
        self.updateShieldApplied()
    }
    
    func removeRestrictions() {
        managedSettingsStore.shield.applications = nil
        managedSettingsStore.shield.categories = nil
        managedSettingsStore.shield.webDomains = nil
        self.updateShieldApplied()
    }
    
    func updateShieldApplied() {
        self.currentAppBlockIsRunning =
            !((managedSettingsStore.shield.applications == nil
            || managedSettingsStore.shield.applications?.isEmpty == true)
            && (managedSettingsStore.shield.categories == nil
                || managedSettingsStore.shield.categories?.isEmpty == true)
            && (managedSettingsStore.shield.webDomains == nil
                || managedSettingsStore.shield.webDomains?.isEmpty == true))
    }
    
    
    // MARK: - SheildConfiguration
    
    func saveShieldConfiguration(_ shieldConfiguration: CueShieldConfigurationModel) {
        let jsonEncoder = JSONEncoder()
        do {
            let encodedData = try jsonEncoder.encode(shieldConfiguration)
            Self.userDefaults.set(encodedData, forKey: Self.sheildConfigurationKey)
        } catch {
            print("(ERROR) failed to encode CueShieldConfigurationModel: ", error.localizedDescription)
        }
    }
    
    nonisolated static func retrieveShieldConfiguration() -> CueShieldConfigurationModel? {
        let jsonDecoder = JSONDecoder()
        
        guard let savedShieldConfigData = Self.userDefaults.value(forKey: Self.sheildConfigurationKey) as? Data else { return nil }
        
        do {
            let shieldConfig = try jsonDecoder.decode(CueShieldConfigurationModel.self, from: savedShieldConfigData)
            return shieldConfig
        } catch {
            print("(ERROR) failed to decode the CueShieldConfiguration: ", error.localizedDescription)
            return nil
        }
    }
}


// MARK: - Sheild Extension

extension ShieldSettings {
    var categories: Set<ActivityCategoryToken>? {
        get {
            guard let applicationCategories = self.applicationCategories else {
                return nil
            }
            guard case .specific(let categoryTokens, _) = applicationCategories
            else {
                return nil
            }
            return categoryTokens
        }
        set {
            if let newValue {
                self.applicationCategories = .specific(newValue, except: [])
            } else {
                self.applicationCategories = nil
            }
        }
    }
}
