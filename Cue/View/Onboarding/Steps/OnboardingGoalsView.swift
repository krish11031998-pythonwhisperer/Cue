//
//  OnboardingGoalsView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 29/09/2026.
//

import SwiftUI
import SFSafeSymbols
import VanorUI

struct OnboardingGoalsView: View {

    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepLayout(includeScrollView: true) {
            OnboardingHeader("What do you want to stay on top of?",
                             subtitle: "Pick as many as you like — we'll shape your first reminders around them.")
        } content: {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(OnboardingGoal.allCases) { goal in
                        goalRow(goal)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.top, 26)
                .padding(.bottom, 12)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
        }
        .sensoryFeedback(.selection, trigger: viewModel.selectedGoals)
    }
    
    private func themeForGoal(_ goal: OnboardingGoal) -> LCHColor {
        .init(color: goal.color)
    }

    private func goalRow(_ goal: OnboardingGoal) -> some View {
        let isSelected = viewModel.selectedGoals.contains(goal)
        return Button {
            withAnimation(.snappy(duration: 0.25)) {
                viewModel.toggle(goal)
            }
        } label: {
            goalButtonLabel(goal)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    
    @ViewBuilder
    private func goalButtonLabel(_ goal: OnboardingGoal) -> some View {
        let theme = themeForGoal(goal)
        let isSelected = viewModel.selectedGoals.contains(goal)
        
        HStack(alignment: .center, spacing: 14) {
            ReminderIconView(icon: .symbol(goal.symbol), foregroundColor: theme.foregroundPrimary, backgroundColor: goal.color, font: .headline)
                .frame(width: 36, height: 36, alignment: .center)
            
            Text(goal.title)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(alignment: .center, content: {
            Capsule()
                .fill(theme.surfacePrimary)
                .stroke(isSelected ? theme.outlinePrimary : Color.clear, style: .init(lineWidth: 2))
        })
        .contentShape(Capsule())
    }
}
