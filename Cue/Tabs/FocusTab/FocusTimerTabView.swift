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
        Group {
#if DEBUG
            ScrollView(.vertical) {
                ForEach(0..<10) { section in
                    Section("Section \(section + 1)") {
                        ScrollView(.horizontal) {
                            HStack(alignment: .center, spacing: 8) {
                                ForEach(0..<5) { _ in
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(Color.red)
                                        .aspectRatio(1, contentMode: .fit)
                                        .containerRelativeFrame(.horizontal) { width, _ in
                                            width * 0.275
                                        }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
            }
#else
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
#endif
        }
        .safeAreaBar(edge: .bottom, alignment: .center, spacing: 8) {
            FocusTimerLaunchControl()
                .padding(.bottom, 8)
                .padding(.horizontal, 24)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
}
