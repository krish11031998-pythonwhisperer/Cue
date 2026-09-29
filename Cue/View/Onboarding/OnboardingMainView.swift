//
//  OnboardingMainview.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/02/2026.
//

import SwiftUI
import VanorUI
import Model

/// Welcome → Goals → Day rhythm → First reminder → Notifications → Focus → Ready.
///
/// Personalise first, create one real reminder, and only then ask for notifications.
struct OnboardingMainView: View {

    @Environment(\.dismiss) var dismiss
    @State private var viewModel: OnboardingViewModel

    init(store: Store) {
        self._viewModel = State(initialValue: .init(store: store))
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            OnboardingTopBar(step: viewModel.step,
                             onBack: viewModel.goBack,
                             onSkip: viewModel.skip)
                .padding(.horizontal, 24)
                .padding(.top, 12)

            ZStack {
                stepView(viewModel.step)
                    .id(viewModel.step)
                    .transition(.blurReplace)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.smooth(duration: 0.35), value: viewModel.step)
        .background(Color.cueItBackground.ignoresSafeArea())
    }

    @ViewBuilder
    private func stepView(_ step: OnboardingStep) -> some View {
        switch step {
        case .welcome:
            WelcomeOnboardingView(getStarted: viewModel.advance)
        case .goals:
            OnboardingGoalsView(viewModel: viewModel)
        case .rhythm:
            OnboardingRhythmView(viewModel: viewModel)
        case .firstReminder:
            OnboardingFirstReminderView(viewModel: viewModel)
        case .notifications:
            OnboardingNotificationsView(viewModel: viewModel)
        case .focus:
            WelcomeFocusView(viewModel: viewModel)
        case .ready:
            OnboardingReadyView(viewModel: viewModel) {
                dismiss()
            }
        }
    }
}

#Preview {
    OnboardingMainView(store: .init())
}
