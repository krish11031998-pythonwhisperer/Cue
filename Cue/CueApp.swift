//
//  CueApp.swift
//  Cue
//
//  Created by Krishna Venkatramani on 17/01/2026.
//

import SwiftUI
import CoreData
import Model
import TipKit

@main
struct CueApp: App {
    @State private var store: Store
    @State private var subscriptionManager: SubscriptionManager
    
    init() {
        // `SubscriptionManager` writes the resolved entitlement into `Store`, which persists it
        // on the `User`, so the two have to share one instance.
        let store = Store()
        _store = State(initialValue: store)
        _subscriptionManager = State(initialValue: SubscriptionManager(store: store))
        
        #if DEBUG
        // Tips fire once and then stay dismissed, which makes iterating on copy painful — start
        // each debug launch from a clean datastore. Must run before `configure`.
        //
        // NOTE: do *not* add `Tips.showAllTipsForTesting()` here. It forces every tip to display
        // regardless of status, so a closed tip never stays invalidated — which pins an ordered
        // `TipGroup` to its first tip and the group never advances.
        try? Tips.resetDatastore()
        #endif
        
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }
    
    var body: some Scene {
        WindowGroup {
            MainTab()
                .environment(store)
                .environment(subscriptionManager)
        }
    }
}
