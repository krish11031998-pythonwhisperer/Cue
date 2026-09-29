//
//  OnboardingReadyView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 29/09/2026.
//

import SwiftUI
import VanorUI

/// Summary of everything set during onboarding.
struct OnboardingReadyView: View {

    let viewModel: OnboardingViewModel
    let openCue: () -> Void

    var body: some View {
        OnboardingStepLayout(includeScrollView: true) {
            OnboardingHeader("You're set.\n",
                             accent: "Cue knows your day.",
                             subtitle: "You can tweak any of this as you go.")
        } content: {
            VStack(alignment: .leading, spacing: 12) {
                summaryRow(symbol: .sparkles,
                           color: Color("rose"),
                           title: "First reminder",
                           detail: firstReminderDetail)
                #if !DEBUG && V1_2
                summaryRow(symbol: .clockFill,
                           color: Color("lavender"),
                           title: "Day rhythm",
                           detail: rhythmDetail)
                #endif
                summaryRow(symbol: .bellFill,
                           color: OnboardingPalette.sky,
                           title: "Notifications",
                           detail: notificationsDetail)
                summaryRow(symbol: .listBullet,
                           color: Color("perwinkle"),
                           title: "Staying on top of",
                           detail: goalsDetail)
            }
            .padding(.top, 26)
            .padding(.bottom, 12)
        }
    }

    // MARK: - Details

    private var firstReminderDetail: String {
        guard let reminder = viewModel.createdReminder else {
            return "Not yet — add one from the + button"
        }
        return "\(reminder.title) · \(reminder.scheduleDescription)"
    }

    private var rhythmDetail: String {
        guard viewModel.rhythmConfirmed else {
            return "Not set"
        }
        return "Starts \(OnboardingViewModel.timeString(minutes: viewModel.dayStartMinutes)) · winds down \(OnboardingViewModel.timeString(minutes: viewModel.windDownMinutes))"
    }

    private var notificationsDetail: String {
        switch viewModel.notificationStatus {
        case .granted:
            return "On"
        case .denied:
            return "Off — turn on in Settings"
        case .notDetermined:
            return "Not set"
        }
    }

    private var goalsDetail: String {
        let goals = viewModel.orderedGoals
        guard !goals.isEmpty else {
            return "Nothing picked yet"
        }
        return goals.map(\.tagName).formatted(.list(type: .and, width: .narrow))
    }

    // MARK: - Row

    @ViewBuilder
    private func summaryRow(symbol: SFSymbol, color: Color, title: String, detail: String) -> some View {
        let theme = LCHColor(color: color)
        
        HStack(alignment: .center, spacing: 14) {
            ReminderIconView(icon: .symbol(symbol), foregroundColor: theme.foregroundPrimary, backgroundColor: theme.baseColor, font: .headline)
                .frame(width: 32, height: 32, alignment: .center)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(minHeight: 64)
        .background(alignment: .center, content: {
            RoundedRectangle(cornerRadius: OnboardingPalette.cardRadius)
                .fill(theme.backgroundPrimary)
                .stroke(theme.outlinePrimary, style: .init(lineWidth: 2))
        })
        .padding(.horizontal, 2)
        .accessibilityElement(children: .combine)
    }
}
