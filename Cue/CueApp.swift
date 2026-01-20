//
//  CueApp.swift
//  Cue
//
//  Created by Krishna Venkatramani on 17/01/2026.
//

import SwiftUI
import CoreData
import Model

@main
struct CueApp: App {
    @State private var store: Store = .init()
    var body: some Scene {
        WindowGroup {
            MainTab(store: store)
        }
    }
}
