//
//  FocusSessionActivityContentView.swift
//  CueWidgets
//

import ActivityKit
import AppIntents
import SwiftUI
import VanorUI
import WidgetKit

/// Root of the Focus Session Live Activity's non-Dynamic-Island presentation.
///
/// One closure feeds three very different canvases: the iPhone Lock Screen, StandBy, and
/// the Apple Watch Smart Stack. `ActivityFamily` is what tells the watch apart - `.small`
/// is the Smart Stack, `.medium` is the phone - so the watch gets a layout built for its
/// card instead of a clipped copy of the Lock Screen's.
struct FocusSessionActivityContentView<ToggleIntent: AppIntent>: View {

    @Environment(\.activityFamily) private var activityFamily
    /// True in StandBy Night Mode and on the watch's always-on display.
    @Environment(\.isLuminanceReduced) private var isLuminanceReduced

    let attributes: FocusSessionLiveActivityAttributes
    let state: FocusSessionLiveActivityAttributes.ContentState
    let toggleIntent: ToggleIntent

    private var theme: LCHColor { .init(hex: attributes.colorHex) }

    var body: some View {
        content
            // StandBy and the Smart Stack strip the Live Activity's margins and draw it
            // edge to edge. Only a container background follows the content out to those
            // edges; a plain `.background` stays inside the (now removed) inset and lets
            // the system backdrop show through around it.
            .containerBackground(for: .widget) {
                background
            }
    }

    @ViewBuilder
    private var content: some View {
        switch activityFamily {
        case .small:
            FocusSessionSmallActivityView(attributes: attributes,
                                          state: state,
                                          toggleIntent: toggleIntent)
        default:
            FocusSessionLockScreenLiveActivityView(attributes: attributes,
                                                   state: state,
                                                   toggleIntent: toggleIntent)
        }
    }

    @ViewBuilder
    private var background: some View {
        if isLuminanceReduced {
            // A three-stop gradient blooms once the panel is tinted and dimmed, so the
            // always-on and Night Mode passes get a flat fill.
            theme.backgroundPrimary
        } else {
            LinearGradient(colors: [theme.backgroundPrimary,
                                    theme.backgroundSecondary,
                                    theme.backgroundTertiary],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
        }
    }
}
