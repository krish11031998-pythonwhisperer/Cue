//
//  FocusSessionSmallActivityView.swift
//  CueWidgets
//

import AppIntents
import SwiftUI
import VanorUI

/// Apple Watch Smart Stack presentation of the Focus Session Live Activity
/// (`ActivityFamily.small`).
///
/// The Smart Stack hands a Live Activity a card barely taller than a row of text, so
/// everything the Lock Screen layout leans on - the 72pt ring, the start/end row, the
/// subtask dots, 20pt of vertical padding - is dropped rather than clipped. What is left
/// is what a wrist glance is for: which session is running, how long is left, and the
/// pause control.
struct FocusSessionSmallActivityView<ToggleIntent: AppIntent>: View {

    /// True on the always-on display, where the panel is dimmed and taps are not
    /// delivered until the wrist is raised.
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    let attributes: FocusSessionLiveActivityAttributes
    let state: FocusSessionLiveActivityAttributes.ContentState
    let toggleIntent: ToggleIntent

    private var theme: LCHColor { .init(hex: attributes.colorHex) }

    /// `ContentState.currentSessionInterval(in:)` is internal to VanorUI, so the whole-run
    /// window is used here - the same one the Dynamic Island's compact leading uses.
    /// `ClosedRange` traps on an inverted range and `endDate` arrives from the app.
    private var interval: ClosedRange<Date> {
        attributes.startDate...max(attributes.startDate, state.endDate)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            FocusSessionActivityIcon(icon: attributes.icon,
                                     theme: theme,
                                     interval: interval,
                                     progress: state.progress,
                                     isPaused: state.isPaused,
                                     size: 34,
                                     lineWidth: 3)

            VStack(alignment: .leading, spacing: 0) {
                Text(attributes.sessionName)
                    .font(.caption2)
                    .foregroundStyle(theme.foregroundTertiary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text.focusCountdown(interval: interval,
                                    pausedAt: state.pausedAt,
                                    showsHours: true)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .fontDesign(.monospaced)
                    .foregroundStyle(theme.foregroundPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !isLuminanceReduced {
                Button(intent: toggleIntent) {
                    Image(systemSymbol: state.isPaused ? .playFill : .pauseFill)
                }
                .buttonStyle(.accessoryButton(size: .small,
                                              withGlass: false,
                                              color: theme.baseColor))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}


// The Smart Stack card is roughly this size on a 45mm watch; the frame is what makes an
// overflowing layout obvious in the canvas rather than on a wrist.
#Preview("Smart Stack - running", traits: .sizeThatFitsLayout) {
    FocusSessionSmallActivityView(attributes: .previewableView(),
                                  state: .previewableContentState(),
                                  toggleIntent: ToggleFocusSessionIntent())
        .frame(width: 184, height: 56)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 16))
}

#Preview("Smart Stack - paused", traits: .sizeThatFitsLayout) {
    FocusSessionSmallActivityView(attributes: .previewableView(),
                                  state: .previewableContentState(pausedAt: .now),
                                  toggleIntent: ToggleFocusSessionIntent())
        .frame(width: 184, height: 56)
        .background(Color.black)
        .clipShape(RoundedRectangle(cornerRadius: 16))
}
