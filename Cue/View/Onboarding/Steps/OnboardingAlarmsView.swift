//
//  OnboardingAlarmsView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 29/09/2026.
//

import SwiftUI
import SFSafeSymbols

/// Shows what an alarm looks like, then asks for AlarmKit access.
struct OnboardingAlarmsView: View {

    /// Drop a screenshot with this name into the asset catalog and it replaces the drawn preview.
    static let screenshotAssetName = "OnboardingAlarmPreview"

    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        OnboardingStepLayout {
            OnboardingHeader("Some reminders can't be missed.\n",
                             accent: "Make them alarms.",
                             subtitle: "Alarms ring through Silent mode and Focus, right on your Lock Screen — even when Cue is closed.")
        } content: {
            VStack(alignment: .center, spacing: 22) {
                preview
                    .frame(maxHeight: .infinity)

                Text(explanation)
                    .font(.subheadline)
                    .foregroundStyle(viewModel.alarmStatus == .denied ? AnyShapeStyle(Color.red) : AnyShapeStyle(HierarchicalShapeStyle.secondary))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 10)
                    .contentTransition(.opacity)
            }
            .padding(.top, 24)
            .animation(.easeInOut, value: viewModel.alarmStatus)
//        } actions: {
//            OnboardingPermissionActions(status: viewModel.alarmStatus,
//                                        isRequesting: viewModel.isRequestingAlarms,
//                                        allowTitle: "Allow alarms",
//                                        onAllow: viewModel.requestAlarms,
//                                        onContinue: viewModel.advance,
//                                        onOpenSettings: viewModel.openAppSettings)
        }
        .task {
            viewModel.refreshAlarmStatus()
        }
        .onChange(of: scenePhase) { _, newPhase in
            // Returning from Settings.
            guard newPhase == .active else { return }
            viewModel.refreshAlarmStatus()
        }
    }

    private var explanation: String {
        switch viewModel.alarmStatus {
        case .notDetermined:
            return "You choose which reminders ring.\nEverything else stays a quiet notification."
        case .granted:
            return "Alarms are on. Switch any reminder to an alarm when you create it."
        case .denied:
            return "Alarms are off for Cue. Turn on Alarms in Settings to use them."
        }
    }

    // MARK: - Preview

    @ViewBuilder
    private var preview: some View {
        if let screenshot = UIImage(named: Self.screenshotAssetName) {
            Image(uiImage: screenshot)
                .resizable()
                .scaledToFit()
                .clipShape(.rect(cornerRadius: 28))
                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 10)
                .accessibilityLabel("Example alarm on the Lock Screen")
        } else {
            OnboardingAlarmIllustration(title: alarmTitle, time: alarmTime)
        }
    }

    private var alarmTitle: String {
        viewModel.createdReminder.map { "\($0.emoji) \($0.title)" } ?? "⏰ Leave for the airport"
    }

    private var alarmTime: Date {
        viewModel.createdReminder?.date ?? Calendar.current.date(bySettingHour: 6, minute: 30, second: 0, of: .now) ?? .now
    }
}

// MARK: - Illustration

/// A drawn Lock Screen with a ringing alarm.
private struct OnboardingAlarmIllustration: View {

    let title: String
    let time: Date

    @State private var ringing: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Text(time.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white.opacity(0.75))
                .padding(.top, 22)

            Text(time.formatted(date: .omitted, time: .shortened))
                .font(.system(size: 54, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Spacer(minLength: 16)

            alarmCard
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: 280, maxHeight: 330)
        .background {
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.12, green: 0.30, blue: 0.39), Color(red: 0.09, green: 0.12, blue: 0.20)],
                                     startPoint: .top,
                                     endPoint: .bottom))
        }
        .shadow(color: .black.opacity(0.18), radius: 18, x: 0, y: 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Example alarm on the Lock Screen: \(title)")
        .onAppear { ringing = true }
    }

    private var alarmCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                Image(systemSymbol: .alarmFill)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(OnboardingPalette.sky)
                    .symbolEffect(.wiggle, options: .repeat(.periodic(delay: 1)), isActive: ringing)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Cue alarm")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.7))
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            }

            HStack(spacing: 10) {
                Text("Snooze")
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(.white.opacity(0.18), in: .capsule)
                Text("Stop")
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(Color.orange, in: .capsule)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
        }
        .padding(14)
        .background(.white.opacity(0.14), in: .rect(cornerRadius: 22, style: .continuous))
    }
}
