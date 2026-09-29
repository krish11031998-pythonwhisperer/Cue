//
//  OnboardingNotificationsView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 29/09/2026.
//

import SwiftUI
import SFSafeSymbols

/// Asks for notifications only after the first reminder exists, with a preview of the alert it
/// will actually receive.
struct OnboardingNotificationsView: View {

    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        OnboardingStepLayout {
            OnboardingHeader("Want Cue to actually get your attention?", subtitle: subtitle)
        } content: {
            VStack(alignment: .center, spacing: 22) {
                notificationPreview

                Text(explanation)
                    .font(.subheadline)
                    .foregroundStyle(viewModel.notificationStatus == .denied ? AnyShapeStyle(Color.red) : AnyShapeStyle(HierarchicalShapeStyle.secondary))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .contentTransition(.opacity)
            }
            .frame(maxHeight: .infinity, alignment: .center)
            .animation(.easeInOut, value: viewModel.notificationStatus)
        }
//        actions: {
//            switch viewModel.notificationStatus {
//            case .notDetermined:
//                Button {
//                    Task { await viewModel.requestNotifications() }
//                } label: {
//                    if viewModel.isRequestingNotifications {
//                        ProgressView()
//                    } else {
//                        Text("Allow notifications")
//                    }
//                }
//                .buttonStyle(.onboardingPrimary)
//                .disabled(viewModel.isRequestingNotifications)
//
//                Button("Maybe later", action: viewModel.advance)
//                    .buttonStyle(.onboardingSecondary)
//            case .granted:
//                Button("Continue", action: viewModel.advance)
//                    .buttonStyle(.onboardingPrimary)
//            case .denied:
//                Button("Open Settings", action: viewModel.openNotificationSettings)
//                    .buttonStyle(.onboardingPrimary)
//
//                Button("Continue without", action: viewModel.advance)
//                    .buttonStyle(.onboardingSecondary)
//            }
//        }
        .task {
            await viewModel.refreshNotificationStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Returning from Settings.
            guard newPhase == .active else { return }
            Task { await viewModel.refreshNotificationStatus() }
        }
    }

    // MARK: - Copy

    private var subtitle: String {
        guard let reminder = viewModel.createdReminder else {
            return "Here's how your reminders will reach you."
        }
        return "Your \(reminder.title.lowercased()) reminder is set for \(reminder.date.formatted(.dateTime.weekday(.wide))) at \(reminder.date.formatted(date: .omitted, time: .shortened)). Here's how it will reach you."
    }

    private var explanation: String {
        switch viewModel.notificationStatus {
        case .notDetermined:
            return "Alarms cut through Silent and Focus modes.\nEverything else stays a quiet notification."
        case .granted:
            return "Notifications are on. Your reminders will reach you on time."
        case .denied:
            return "Notifications are off for Cue, so reminders can't reach you. Turn them on in Settings."
        }
    }

    // MARK: - Preview

    private var notificationPreview: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(OnboardingPalette.sky)
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemSymbol: .bellFill)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(viewModel.createdReminder.map { "\($0.emoji) \($0.title)" } ?? "Your reminder")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("now")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text("It's time. Tap to open it in Cue.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .background(OnboardingPalette.card.opacity(0.92), in: .rect(cornerRadius: 22))
        .shadow(color: .black.opacity(0.13), radius: 13, x: 0, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Example notification")
    }
}
