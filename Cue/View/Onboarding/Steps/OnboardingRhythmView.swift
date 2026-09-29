//
//  OnboardingRhythmView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 29/09/2026.
//

import SwiftUI
import SFSafeSymbols
import VanorUI

#if !DEBUG && V1_2
struct OnboardingRhythmView: View {

    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepLayout(includeScrollView: false) {
            OnboardingHeader("When does your day start and end?",
                             subtitle: "We'll place reminders and focus blocks inside your real day.")
        } content: {
            ScrollView {
                VStack(alignment: .center, spacing: 16) {
                    dayStartPicker
                    windDownRow
                }
                .padding(.top, 26)
                .padding(.bottom, 12)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
//        actions: {
//            Button("Continue", action: viewModel.confirmRhythm)
//                .buttonStyle(.onboardingPrimary)
//        }
    }

    private var dayStartPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Day starts", systemSymbol: .sunriseFill)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 16)
                .padding(.top, 14)

            Picker("Day starts", selection: $viewModel.dayStartMinutes) {
                ForEach(OnboardingViewModel.dayStartOptions, id: \.self) { minutes in
                    Text(OnboardingViewModel.timeString(minutes: minutes))
                        .font(.title3.weight(.semibold))
                        .tag(minutes)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 190)
            .clipped()
        }
        .background(OnboardingPalette.card, in: .rect(cornerRadius: OnboardingPalette.cardRadius))
    }
    
    var theme: LCHColor {
        .init(color: Color.perwinkle)
    }

    private var windDownRow: some View {
        HStack(alignment: .center, spacing: 14) {
            ReminderIconView(icon: .symbol(.moonFill), foregroundColor: theme.foregroundPrimary, backgroundColor: theme.baseColor, font: .headline)
                .frame(width: 36, height: 36, alignment: .center)

            Text("Wind down")
                .font(.body.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)

            Picker("Wind down", selection: $viewModel.windDownMinutes) {
                ForEach(OnboardingViewModel.windDownOptions, id: \.self) { minutes in
                    Text(OnboardingViewModel.timeString(minutes: minutes))
                        .tag(minutes)
                }
            }
            .pickerStyle(.menu)
            .tint(OnboardingPalette.skyInk)
            .fontWeight(.semibold)
            .labelsHidden()
        }
        .padding(.leading, 16)
        .padding(.trailing, 6)
        .padding(.vertical, 14)
        .frame(minHeight: 64)
        .background(OnboardingPalette.card, in: .rect(cornerRadius: OnboardingPalette.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: OnboardingPalette.cardRadius)
                .strokeBorder(OnboardingPalette.line, lineWidth: 1.5)
        }
    }
}
#endif
