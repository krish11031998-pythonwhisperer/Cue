//
//  FocusAlarmLiveActivity.swift
//  CueWidgets
//

import WidgetKit
import SwiftUI
import AlarmKit
import Model

struct FocusAlarmLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<CueFocusAlarmAttributes>.self) { context in
            HStack(alignment: .center, spacing: 12) {
                sessionIcon(metadata: context.attributes.metadata, tint: tint(for: context.attributes))
                VStack(alignment: .leading, spacing: 2) {
                    sessionTitle(metadata: context.attributes.metadata)
                    sessionSubtitle(metadata: context.attributes.metadata)
                }
                Spacer(minLength: 0)
                countdown(state: context.state, maxWidth: 90)
                    .font(.title3)
            }
            .padding()
            .tint(tint(for: context.attributes))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(alignment: .center, spacing: 8) {
                        sessionIcon(metadata: context.attributes.metadata,
                                    tint: tint(for: context.attributes),
                                    size: 24)
                        sessionTitle(metadata: context.attributes.metadata)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    countdown(state: context.state, maxWidth: 80)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    sessionSubtitle(metadata: context.attributes.metadata)
                }
            } compactLeading: {
                sessionIcon(metadata: context.attributes.metadata,
                            tint: tint(for: context.attributes),
                            size: 18)
            } compactTrailing: {
                countdown(state: context.state, maxWidth: 50)
            } minimal: {
                sessionIcon(metadata: context.attributes.metadata,
                            tint: tint(for: context.attributes),
                            size: 18)
            }
        }
    }


    // MARK: - Session Attributes

    /// The session's colour, as handed over by `CueAlarmManager` when the alarm was scheduled.
    private func tint(for attributes: AlarmAttributes<CueFocusAlarmAttributes>) -> Color {
        attributes.tintColor
    }

    /// Symbol and emoji icons are rendered apart: an emoji has to keep its own colours,
    /// while a symbol picks up the session's tint.
    @ViewBuilder
    private func sessionIcon(metadata: CueFocusAlarmAttributes?, tint: Color, size: CGFloat = 32) -> some View {
        Group {
            if let emoji = metadata?.icon.emoji {
                Text(emoji)
            } else {
                Image(systemName: metadata?.icon.symbol ?? "timer")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(tint)
            }
        }
        .font(.system(size: size * 0.8))
        .frame(width: size, height: size)
    }

    private func sessionTitle(metadata: CueFocusAlarmAttributes?) -> some View {
        Text(metadata?.title ?? "Focus Timer")
            .font(.headline)
            .fontWeight(.semibold)
            .lineLimit(1)
    }

    private func sessionSubtitle(metadata: CueFocusAlarmAttributes?) -> some View {
        Text(metadata?.subtitle ?? "")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }


    // MARK: - Countdown View

    private func countdown(state: AlarmPresentationState, maxWidth: CGFloat = .infinity) -> some View {
        Group {
            switch state.mode {
            case .countdown(let countdown):
                Text(timerInterval: Date.now ... countdown.fireDate, countsDown: true)
            case .paused(let pausedState):
                let remaining = Duration.seconds(pausedState.totalCountdownDuration - pausedState.previouslyElapsedDuration)
                let pattern: Duration.TimeFormatStyle.Pattern = remaining > .seconds(60 * 60) ? .hourMinuteSecond : .minuteSecond
                Text(remaining.formatted(.time(pattern: pattern)))
            default:
                EmptyView()
            }
        }
        .monospacedDigit()
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: maxWidth, alignment: .leading)
    }
}
