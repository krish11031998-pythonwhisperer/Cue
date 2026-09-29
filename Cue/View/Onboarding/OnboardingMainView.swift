//
//  OnboardingMainview.swift
//  Cue
//
//  Created by Krishna Venkatramani on 09/02/2026.
//

import SwiftUI
import VanorUI
import Model

/// Welcome → Goals → Day rhythm → First reminder → Notifications → Alarms → Focus → Block apps → Ready.
///
/// Personalise first, create one real reminder, and only then ask for notifications.
struct OnboardingMainView: View {

    @Environment(\.dismiss) var dismiss
    @State private var viewModel: OnboardingViewModel

    init(store: Store) {
        self._viewModel = State(initialValue: .init(store: store))
    }

    var body: some View {
        ZStack {
            stepView(viewModel.step)
                .id(viewModel.step)
                .transition(.blurReplace)
        }
        .frame(maxHeight: .infinity, alignment: .leading)
        .safeAreaInset(edge: .top, alignment: .center, spacing: 8, content: {
            OnboardingTopBar(step: viewModel.step,
                             onBack: viewModel.goBack,
                             onSkip: viewModel.skip)
                .padding(.horizontal, 16)
                .padding(.top, 12)
        })
        .task {
            self.viewModel.dismiss = {
                dismiss()
            }
        }
        .safeAreaInset(edge: .bottom, content: {
            footerView
        })
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
        #if !DEBUG && V1_2
        case .rhythm:
            OnboardingRhythmView(viewModel: viewModel)
        #endif
        case .firstReminder:
            OnboardingFirstReminderView(viewModel: viewModel)
        case .notifications:
            OnboardingNotificationsView(viewModel: viewModel)
        case .alarms:
            OnboardingAlarmsView(viewModel: viewModel)
        case .focus:
            WelcomeFocusView(viewModel: viewModel)
        case .blockApps:
            OnboardingBlockAppsView(viewModel: viewModel)
        case .ready:
            OnboardingReadyView(viewModel: viewModel) {
                dismiss()
            }
        }
    }
    
    private var primaryTitle: String {
        switch viewModel.step {
        case .welcome:
            return "Get started"
        case .goals:
            return "Continue"
        #if !DEBUG && V1_2
        case .rhythm:
            return ""
        #endif
        case .firstReminder:
            return "Create"
        case .notifications:
            switch viewModel.notificationStatus {
            case .notDetermined:
                    return "Allow notifications"
            case .granted:
                return "Continue"
            case .denied:
                return "Open Settings"
            }
        case .alarms:
            return "Allow Alarms"
        case .blockApps:
            return "Allow App Blocking"
        case .focus:
            return "Next"
        case .ready:
            return "Open cue:it"
        }
    }
    
    private var secondaryTitle: String {
        switch viewModel.step {
        case .welcome, .goals, .firstReminder, .focus, .alarms, .blockApps:
            return "Not now"
        #if !DEBUG && V1_2
        case .rhythm:
            return ""
        #endif
        case .notifications:
            switch viewModel.notificationStatus {
            case .notDetermined, .granted:
                return "Maybe later"
            case .denied:
                return "Continue without"
            }
        case .ready:
            return "Open cue:it"
        }
    }
    
    private var showSecondaryButton: Bool {
        switch viewModel.step {
        case .welcome, .goals, .firstReminder, .focus, .ready:
            return false
        case .notifications:
            switch viewModel.notificationStatus {
            case .notDetermined, .denied:
                return true
            case .granted:
                return false
            }
        case .alarms, .blockApps:
            return true
        }
    }
    
    @ViewBuilder
    private var footerView: some View {
        VStack(alignment: .center, spacing: 10) {
            Button(action: viewModel.primaryButtonAction) {
                if viewModel.loadingButton {
                    ProgressView()
                        .controlSize(.regular)
                } else {
                    Text(primaryTitle)
                        .font(.headline)
                }
            }
            .buttonStyle(.onboardingPrimary)
            .controlSize(.large)
            .contentTransition(.numericText())
            .disabled(viewModel.loadingButton)
            
            Button(secondaryTitle) {
                // Do something
                viewModel.advance()
            }
            .buttonStyle(.onboardingSecondary)
            .controlSize(.large)
            .opacity(showSecondaryButton ? 1 : 0)
            .disabled(!showSecondaryButton)
        }
        .padding(.horizontal, 16)
        .animation(.easeInOut, value: primaryTitle)
    }
}

#Preview {
    OnboardingMainView(store: .init())
}
