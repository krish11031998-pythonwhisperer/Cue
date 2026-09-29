//
//  WelcomeFocusView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/02/2026.
//

import SwiftUI
import VanorUI

struct WelcomeFocusView: View {

    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepLayout(includeScrollView: false) {
            OnboardingHeader("Focus with timers\n",
                             accent: "while you work",
                             subtitle: "Try it — three seconds, right here.")
        } content: {
            FocusCountdownView(countdownViewType: .circle, targetDuration: 3, theme: Color.proSky) {
                guard case .completed = $0 else { return }
                viewModel.focusDemoCompleted = true
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(.horizontal, 44)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
//        actions: {
//            Button("Next", action: viewModel.advance)
//                .buttonStyle(.onboardingPrimary)
//                .disabled(!viewModel.focusDemoCompleted)
//        }
        .sensoryFeedback(.success, trigger: viewModel.focusDemoCompleted) { _, completed in completed }
    }
}
