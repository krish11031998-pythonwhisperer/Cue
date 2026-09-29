//
//  OnboardingGoalsView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 29/09/2026.
//

import SwiftUI
import SFSafeSymbols

struct OnboardingGoalsView: View {

    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepLayout {
            OnboardingHeader("What do you want to stay on top of?",
                             subtitle: "Pick as many as you like — we'll shape your first reminders around them.")
        } content: {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(OnboardingGoal.allCases) { goal in
                        goalRow(goal)
                    }
                }
                .padding(.top, 26)
                .padding(.bottom, 12)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
//        actions: {
//            Button("Continue", action: viewModel.advance)
//                .buttonStyle(.onboardingPrimary)
//        }
        .sensoryFeedback(.selection, trigger: viewModel.selectedGoals)
    }

    private func goalRow(_ goal: OnboardingGoal) -> some View {
        let isSelected = viewModel.selectedGoals.contains(goal)
        return Button {
            withAnimation(.snappy(duration: 0.25)) {
                viewModel.toggle(goal)
            }
        } label: {
            HStack(alignment: .center, spacing: 14) {
                OnboardingIconTile(symbol: goal.symbol, color: goal.color, size: 34)

                Text(goal.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ZStack {
                    if isSelected {
                        Circle()
                            .fill(goal.color)
                        Image(systemSymbol: .checkmark)
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(.white)
                    } else {
                        Circle()
                            .strokeBorder(OnboardingPalette.checkOutline, lineWidth: 1.5)
                    }
                }
                .frame(width: 26, height: 26)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(minHeight: 64)
            .background(OnboardingPalette.card, in: .rect(cornerRadius: OnboardingPalette.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: OnboardingPalette.cardRadius)
                    .strokeBorder(isSelected ? goal.color : OnboardingPalette.line, lineWidth: 2)
            }
            .contentShape(.rect(cornerRadius: OnboardingPalette.cardRadius))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
