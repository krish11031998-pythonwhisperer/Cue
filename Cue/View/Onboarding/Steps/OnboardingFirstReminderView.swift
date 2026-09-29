//
//  OnboardingFirstReminderView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 29/09/2026.
//

import SwiftUI
import SFSafeSymbols
import VanorUI

struct OnboardingFirstReminderView: View {

    @Environment(\.theme) var theme
    @Bindable var viewModel: OnboardingViewModel
    @FocusState private var fieldFocused: Bool

    var body: some View {
        OnboardingStepLayout(includeScrollView: true) {
            OnboardingHeader("What's the first routine you want to build?",
                             subtitle: "One real thing. You can change it any time.")
        } content: {
            VStack(alignment: .leading, spacing: 12) {
                reminderField
                    .padding(.horizontal, 2)
                
                if let draft = viewModel.draft {
                    draftDetails(draft)
                        .transition(.blurReplace)
                } else {
                    Group {
                        Text("Or start from one of these:")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                            .padding(.top, 14)
                        
                        OverFlowingHorizontalLayout(horizontalSpacing: 10, verticalSpacing: 10) {
                            ForEach(viewModel.suggestions) { suggestion in
                                suggestionChip(suggestion)
                            }
                        }
                    }
                    .transition(.blurReplace)
                }
                
            }
            .padding(.top, 24)
            .padding(.bottom, 12)
            .animation(.snappy, value: viewModel.draft)
        }
        .onChange(of: viewModel.reminderText) {
            viewModel.reminderTextChanged()
        }
        .task(id: viewModel.reminderText) {
            // Read the sentence once typing pauses.
            try? await Task.sleep(for: .milliseconds(800))
            guard !Task.isCancelled else { return }
            await viewModel.interpretTypedReminder()
        }
    }

    // MARK: - Field

    private var reminderField: some View {
        HStack(alignment: .center, spacing: 13) {
            Circle()
                .fill(theme.baseColor)
                .frame(width: 36, height: 36)
                .overlay {
                    if viewModel.isInterpreting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Image(systemSymbol: .sparkles)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }
                .accessibilityHidden(true)

            TextField("e.g. Gym after work on Tuesday", text: $viewModel.reminderText)
                .font(.body.weight(.medium))
                .focused($fieldFocused)
                .submitLabel(.done)
                .onSubmit {
                    Task { await viewModel.interpretTypedReminder() }
                }
        }
        .padding(16)
        .background(alignment: .center, content: {
            Capsule()
                .fill(theme.backgroundPrimary)
                .stroke(fieldFocused ? theme.outlinePrimary : theme.outlineTertiary, style: .init(lineWidth: 2))
        })
        .animation(.easeInOut(duration: 0.2), value: fieldFocused)
    }

    // MARK: - Draft

    private func draftDetails(_ draft: OnboardingReminderDraft) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your first routine:")
                .font(.title3.weight(.semibold))
                .foregroundStyle(theme.foregroundTertiary)
            
            ReminderView(model: .init(title: draft.title,
                                      icon: .emoji(.init(draft.emoji)),
                                      lightColor: Color.sky,
                                      darkColor: Color.sky,
                                      time: draft.date,
                                      state: .showDisplayOptions(
                                        .init(time: draft.date.formatted(date: .omitted, time: .shortened),
                                              date: draft.repeatDescription,
                                              schedule: draft.scheduleDescription,
                                              delete: nil,
                                              edit: nil)
                                      ),
                                      tags: [],
                                      logReminder: nil,
                                      deleteReminder: nil))
            .padding(.horizontal, 2)
        }
        .padding(.top, 24)
    }

    private func detailChip(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.primary)
            .lineLimit(1)
            .padding(.horizontal, 13)
            .padding(.vertical, 7)
            .background(color.opacity(0.28), in: .rect(cornerRadius: 14))
    }

    // MARK: - Suggestions

    private func suggestionChip(_ suggestion: OnboardingReminderSuggestion) -> some View {
        let isSelected = viewModel.draft?.sourceText == suggestion.title
        return Button {
            fieldFocused = false
            viewModel.select(suggestion)
        } label: {
            Text(suggestion.title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(OnboardingPalette.card, in: .rect(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(isSelected ? OnboardingPalette.sky : OnboardingPalette.line, lineWidth: 1.5)
                }
                .contentShape(.rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
