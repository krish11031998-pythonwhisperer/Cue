//
//  FocusTimerTabView.swift
//  Kyu
//
//  Created by Krishna Venkatramani on 05/04/2026.
//

import Foundation
import SwiftUI
import VanorUI
import Model

extension Notification.Name {
    static let presentQuickStart = Notification.Name("presentQuickStart")
    static let currentFTSession = Notification.Name("currentFTSession")
}

struct FocusTimerTabView: View {
    
    @Bindable private var coordinator: FocusSessionCoordinator
    @State private var viewModel: FocusTimeViewModel = .init()
    @Environment(Store.self) var store
    
    init(coordinator: FocusSessionCoordinator) {
        self.coordinator = coordinator
    }
    
    var body: some View {
        FocusRootView(coordinator: coordinator)
    }
    
}


#Preview {
    FocusTimerTabView(coordinator: .previawableSessionCoordinator)
}
