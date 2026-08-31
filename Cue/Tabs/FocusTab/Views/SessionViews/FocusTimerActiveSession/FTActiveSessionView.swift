//
//  FTActiveSessionView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 30/08/2026.
//

import SwiftUI
import VanorUI
import Model


struct FTActiveSessionView: View {
    
    @Environment(\.dismiss) var dismiss
    @Bindable private var coordinator: FocusSessionCoordinator
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.theme) var theme
    @State private var frame: CGRect = .zero
    let focusSessionModel: FocusSessionModel
    
    init(coordinator: FocusSessionCoordinator, focusSessionModel: FocusSessionModel) {
        self.coordinator = coordinator
        self.focusSessionModel = focusSessionModel
    }
    
    #warning("should use injected `FocusSessionModel` icon")
    private var icon: Icon? {
        return .symbol(.timer)
    }
    
    var body: some View {
        FTSessionView(coordinator: coordinator, viewType: .activeSession) {
            GeometryReader { proxy in
                let safeInsets = proxy.safeAreaInsets
                let globalFrame = proxy.frame(in: .global)
                let circleSize: CGSize = .init(width: globalFrame.width - 16, height: globalFrame.width - 16)
                let center: CGPoint = .init(x: globalFrame.midX, y: globalFrame.midY - safeInsets.top.half - circleSize.height.half.half)
                
                ZStack(alignment: .center) {
                    Color.cueItBackground
                        .ignoresSafeArea(edges: .vertical)
                    
                    FocusCountdownView(countdownViewType: .circle,
                                       targetDuration: coordinator.timerDuration,
                                       theme: theme) {
                        InnerContent(icon: icon)
                    }
                    .environment(coordinator)
                    .padding(.horizontal, 8)
                    .position(center)
                }
                .onAppear {
                    print("(DEBUG) safeAreaInsets: \(safeInsets) - globalFrame: \(globalFrame) - circleSize: \(circleSize) - center: \(center)")
                }
            }
        }
        .task(id: focusSessionModel) {
            coordinator.startWithFocusSessionModel(focusSessionModel)
        }
    }
    
    
    // MARK: - InnerContent
    
    private struct InnerContent: View {
        
        @Environment(FocusSessionCoordinator.self) var coordinator
        @Environment(\.theme) var theme
        let icon: Icon?
        
        var font: FocusSessionTimeCountdownView.FontType {
            #if NEW_COUNTDOWN_TIMER
            return .custom(.bitcountMedium(style: .extraLargeTitle))
            #else
            return .defaultLargeTitle
            #endif
        }
        
        var body: some View {
            ZStack(alignment: .center) {
                if coordinator.state == .idle || coordinator.state == .reset {
                    Color.clear
                } else {
                    FocusSessionTimeCountdownView(countdownViewType: .circle,
                                                  theme: theme,
                                                  remainingTime: coordinator.remainingTimeDuration,
                                                  isCompleted: false,
                                                  icon: icon,
                                                  font: font)
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        
    }
    
}
