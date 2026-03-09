//
//  FocusTimerTabView.swift
//  Kyu
//
//  Created by Krishna Venkatramani on 05/04/2026.
//

import Foundation
import SwiftUI
import VanorUI

struct FocusTimerTabView: View {
    
    @State private var presentFocusTimerSheet: Bool = false
    @State private var timeDuration: TimeInterval? = nil
    
    var body: some View {
        ZStack(alignment: .center) {
            if let timeDuration {
                TimerView(reminder: nil, loggedTasks: .init(), duration: timeDuration)
            } else {
                Button("Start Focus", systemSymbol: .timer) {
                    self.presentFocusTimerSheet.toggle()
                }
                .tint(.proSky.baseColor)
                .buttonStyle(.glassProminent)
            }
        }
        .sheet(isPresented: $presentFocusTimerSheet) {
            TimerSheet(reminderModels: []) { _, timeDuration in
                withAnimation {
                    self.presentFocusTimerSheet = false
                } completion: {
                    self.timeDuration = timeDuration
                }
            }
            .fittedPresentationDetent()
        }
    }
    
}
