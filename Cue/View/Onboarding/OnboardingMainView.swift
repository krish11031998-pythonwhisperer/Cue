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
                .padding(.horizontal, 24)
                .padding(.top, 12)
        })
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
        case .focus:
            WelcomeFocusView(viewModel: viewModel)
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
            return "Create My First Routine"
        case .notifications:
            switch viewModel.notificationStatus {
            case .notDetermined:
                    return "Allow notifications"
            case .granted:
                return "Continue"
            case .denied:
                return "Open Settings"
            }
        case .focus:
            return "Next"
        case .ready:
            return "Open cue:it"
        }
    }
    
    private var secondaryTitle: String {
        switch viewModel.step {
        case .welcome, .goals, .firstReminder, .focus:
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
        }
    }
    
    @ViewBuilder
    private var footerView: some View {
        VStack(alignment: .center, spacing: 10) {
            Button(primaryTitle) {
                viewModel.advance()
            }
            .buttonStyle(.onboardingPrimary)
            .controlSize(.large)
            
            Button(secondaryTitle) {
                // Do soemthing
            }
            .buttonStyle(.onboardingSecondary)
            .controlSize(.large)
            .opacity(showSecondaryButton ? 1 : 0)
            .disabled(!showSecondaryButton)
        }
        .padding(.horizontal, 16)
        .animation(.easeInOut, value: primaryTitle)
//        switch viewModel.step {
//        case .welcome:
//            VStack(alignment: .center, spacing: 10) {
//                Button("Get started") {
//                    viewModel.advance()
//                }
//                .buttonStyle(.onboardingPrimary)
//                .controlSize(.large)
//
//                Text("cue:ai requires cue:it Pro and a device that supports Apple Intelligence.")
//                    .font(.caption2)
//                    .foregroundStyle(.secondary)
//                    .multilineTextAlignment(.center)
//            }
//            .padding(.horizontal, 16)
//        case .goals:
//            VStack(alignment: .center, spacing: 10) {
//                Button("Continue") {
//                    viewModel.advance()
//                }
//                .buttonStyle(.onboardingPrimary)
//                .controlSize(.large)
//            }
//            .padding(.horizontal, 16)
//            
//        #if !DEBUG && V1_2
//        case .rhythm:
//            EmptyView()
//        #endif
//        case .firstReminder, .notifications, .focus, .ready:
//            EmptyView()
//        }
    }
}

#Preview {
    OnboardingMainView(store: .init())
}
