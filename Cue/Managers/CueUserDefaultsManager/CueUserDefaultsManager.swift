//
//  CueUserDefaultsManager.swift
//  Kyu
//
//  Created by Krishna Venkatramani on 10/02/2026.
//

import Foundation

class CueUserDefaultsManager {
    
    enum Keys: String {
        case hasShowOnboarding = "has_show_onboarding"
    }
    
    private init() {}
    
    static let shared: CueUserDefaultsManager = .init()
    
    subscript<T>(_ key: Keys) -> T? {
        get {
            UserDefaults.standard.value(forKey: key.rawValue) as? T
        }
        
        set {
            UserDefaults.standard.setValue(newValue, forKey: key.rawValue)
        }
    }
    
}
