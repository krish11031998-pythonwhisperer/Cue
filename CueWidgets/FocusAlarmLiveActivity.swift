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
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.metadata?.title ?? "Focus Timer")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                countdown(state: context.state)
            }
            .padding()
            .tint(context.attributes.tintColor)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Text(context.attributes.metadata?.title ?? "Focus Timer")
                        .font(.headline)
                        .lineLimit(1)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    countdown(state: context.state, maxWidth: 80)
                }
            } compactLeading: {
                Image(systemName: "timer")
            } compactTrailing: {
                countdown(state: context.state, maxWidth: 50)
            } minimal: {
                Image(systemName: "timer")
            }
        }
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
