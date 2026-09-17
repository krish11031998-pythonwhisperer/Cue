//
//  FocusAlarmActivityViews.swift
//  CueWidgets
//

import ActivityKit
import AlarmKit
import Model
import SwiftUI
import WidgetKit

/// Root of the Focus alarm Live Activity's non-Dynamic-Island presentation.
///
/// Like the session activity, the same closure is asked for the Lock Screen, StandBy and
/// the Apple Watch Smart Stack. `.small` is the watch card, which is far too short for the
/// title / subtitle / countdown row the Lock Screen draws.
struct FocusAlarmActivityContentView: View {

    @Environment(\.activityFamily) private var activityFamily

    let attributes: AlarmAttributes<CueFocusAlarmAttributes>
    let state: AlarmPresentationState

    var body: some View {
        switch activityFamily {
        case .small:
            smallBody
        default:
            lockScreenBody
        }
    }


    // MARK: - Lock Screen / StandBy

    private var lockScreenBody: some View {
        HStack(alignment: .center, spacing: 12) {
            FocusAlarmSessionIcon(metadata: attributes.metadata, tint: attributes.tintColor)
            VStack(alignment: .leading, spacing: 2) {
                FocusAlarmSessionTitle(metadata: attributes.metadata)
                FocusAlarmSessionSubtitle(metadata: attributes.metadata)
            }
            Spacer(minLength: 0)
            FocusAlarmCountdown(state: state, maxWidth: 90)
                .font(.title3)
        }
        .padding()
        .tint(attributes.tintColor)
    }


    // MARK: - Apple Watch Smart Stack

    /// No subtitle and a smaller icon: the Smart Stack card only has room for the session
    /// name and the time left.
    private var smallBody: some View {
        HStack(alignment: .center, spacing: 8) {
            FocusAlarmSessionIcon(metadata: attributes.metadata,
                                  tint: attributes.tintColor,
                                  size: 24)
            FocusAlarmSessionTitle(metadata: attributes.metadata, font: .caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            FocusAlarmCountdown(state: state, maxWidth: 72)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .tint(attributes.tintColor)
    }
}


// MARK: - Session Icon

/// Symbol and emoji icons are rendered apart: an emoji has to keep its own colours,
/// while a symbol picks up the session's tint.
struct FocusAlarmSessionIcon: View {

    let metadata: CueFocusAlarmAttributes?
    let tint: Color
    var size: CGFloat = 32

    var body: some View {
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
}


// MARK: - Session Text

struct FocusAlarmSessionTitle: View {

    let metadata: CueFocusAlarmAttributes?
    var font: Font = .headline

    var body: some View {
        Text(metadata?.title ?? "Focus Timer")
            .font(font)
            .fontWeight(.semibold)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}

struct FocusAlarmSessionSubtitle: View {

    let metadata: CueFocusAlarmAttributes?

    var body: some View {
        Text(metadata?.subtitle ?? "")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}


// MARK: - Countdown

struct FocusAlarmCountdown: View {

    let state: AlarmPresentationState
    var maxWidth: CGFloat = .infinity

    var body: some View {
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
