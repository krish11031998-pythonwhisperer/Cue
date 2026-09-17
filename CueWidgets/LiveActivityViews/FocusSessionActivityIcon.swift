//
//  FocusSessionActivityIcon.swift
//  CueWidgets
//

import SwiftUI
import VanorUI

/// The session's icon with its progress ring, rendered in a single layout pass.
///
/// `VanorUI.FocusLiveActivitySessionIcon` sizes its emoji from an
/// `onGeometryChange` -> `@State` -> re-render round trip. A Live Activity is rendered
/// once by the widget extension and archived, and `@State` written during that pass never
/// comes back round, so the emoji is asked for at `.zero`, `ImageRenderer` hands back
/// `nil`, and the icon falls through to its `questionmark` placeholder. It shows up on
/// StandBy and on the watch, where nothing else forces a redraw.
///
/// Drawing the emoji as `Text` needs no measurement, so it is right the first time.
struct FocusSessionActivityIcon: View {

    let icon: FocusSessionLiveActivityAttributes.Icon
    let theme: LCHColor
    /// Window the ring fills over - the running Pomodoro session, or the whole run.
    let interval: ClosedRange<Date>
    let progress: CGFloat
    let isPaused: Bool
    let size: CGFloat
    let lineWidth: CGFloat

    init(icon: FocusSessionLiveActivityAttributes.Icon,
         theme: LCHColor,
         interval: ClosedRange<Date>,
         progress: CGFloat,
         isPaused: Bool,
         size: CGFloat,
         lineWidth: CGFloat = 3) {
        self.icon = icon
        self.theme = theme
        self.interval = interval
        self.progress = progress
        self.isPaused = isPaused
        self.size = size
        self.lineWidth = lineWidth
    }

    /// Inset that keeps the glyph clear of the ring.
    private var inset: CGFloat { lineWidth + size * 0.16 }

    var body: some View {
        ZStack(alignment: .center) {
            Circle()
                .fill(theme.backgroundSecondary)

            ring

            glyph
                .padding(.all, inset)
        }
        .frame(width: size, height: size, alignment: .center)
    }


    // MARK: - Ring

    @ViewBuilder
    private var ring: some View {
        Group {
            if isPaused {
                // A `timerInterval` ring cannot be frozen, so a paused session draws the
                // remaining fraction statically instead.
                ProgressView(value: min(max(1 - progress, 0), 1))
            } else {
                ProgressView(timerInterval: interval, countsDown: true) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            }
        }
        .progressViewStyle(.circular)
        .tint(theme.outlinePrimary)
    }


    // MARK: - Glyph

    @ViewBuilder
    private var glyph: some View {
        if let emoji = icon.emoji, !emoji.isEmpty {
            Text(emoji)
                .font(.system(size: size * 0.5))
                .minimumScaleFactor(0.01)
                .lineLimit(1)
        } else {
            Image(systemName: icon.symbol ?? "timer")
                .resizable()
                .scaledToFit()
                .foregroundStyle(theme.foregroundPrimary)
        }
    }
}
