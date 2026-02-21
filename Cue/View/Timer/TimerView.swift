//
//  TimerView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 12/02/2026.
//

import SwiftUI
import Model
import VanorUI

struct TimerView: View {
    
    let duration: TimeInterval
    @State private var viewModel: TimerViewModel
    @Environment(\.dismiss) var dismiss
    
    init(reminder: ReminderModel?, duration: TimeInterval) {
        self.duration = duration
        self._viewModel = .init(initialValue: .init(reminderModel: reminder))
    }
    
    var durationTimeSting: String {
        let startTime = Date.now
        let endTime = startTime.addingTimeInterval(duration)
        
        let startTimeString = startTime.timeBuilder()
        let endTimeString = endTime.timeBuilder()
        
        return "\(startTimeString) → \(endTimeString)"
        
    }
    
    var body: some View {
        NavigationView {
            GeometryReader { proxy in
                VStack(alignment: .center, spacing: 0) {
                    TimerHeaderView(reminder: viewModel.reminderModel, duration: duration)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                        .frame(height: proxy.size.height * 0.15, alignment: .center)
                        .padding(.bottom, proxy.size.height * 0.35 - proxy.size.width.half)
                    
                    FocusCountdownView(targetDuration: duration,
                                       mode: .asTimer,
                                       theme: Color.proSky,
                                       stateUpdateHandler: viewModel.updatePresentSheet(_:))
                    .aspectRatio(1, contentMode: .fit)
                    .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }, action: { newValue in
                        self.viewModel.frameOfCountdown = newValue
                    })
                    
                    
                    
                }
                .sheet(isPresented: $viewModel.presentSheet, content: {
                    if !viewModel.tasks.isEmpty {
                        TimerReminderTasksView(reminderTaskModels: viewModel.tasks,
                                               selectedPresentedDetent: nil)
                        .presentationDetents([.height(detentHeight(proxy)), .fraction(0.7)])
                        .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.7)))
                        .presentationDragIndicator(.visible)
                        .presentationContentInteraction(.scrolls)
                    }
                })
                
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(alignment: .top) {
                ZStack(alignment: .top) {
                    Color.systemBackground
                    RadialGradient(stops: [.init(color: Color.proSky.baseColor, location: 0), .init(color: Color.proSky.baseColor.opacity(0), location: 1)], center: .top, startRadius: 0, endRadius: 300)
                }
                    .ignoresSafeArea(edges: .vertical)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("", systemSymbol: .xmark) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func detentHeight(_ proxy: GeometryProxy) -> CGFloat {
        proxy.size.height + proxy.safeAreaInsets.top - 24 - viewModel.frameOfCountdown.maxY
    }
    
}
