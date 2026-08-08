//
//  ReminderAlarmLiveActivity.swift
//  CueWidgets
//

import WidgetKit
import SwiftUI
import AlarmKit
import Model

struct ReminderAlarmLiveActivity: Widget {

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<CueAlarmAttributes>.self) { context in
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    alarmTitle(attributes: context.attributes, state: context.state)
                    Spacer()
                    reminderView(metadata: context.attributes.metadata)
                }
                countdown(state: context.state)
            }
            .padding()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    alarmTitle(attributes: context.attributes, state: context.state)
                }

                DynamicIslandExpandedRegion(.trailing) {
                    reminderView(metadata: context.attributes.metadata)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    countdown(state: context.state)
                }
            } compactLeading: {
                countdown(state: context.state)
            } compactTrailing: {
                AlarmProgressView(icon: context.attributes.metadata, mode: context.state.mode, tint: .accentColor)
            } minimal: {
                AlarmProgressView(icon: context.attributes.metadata, mode: context.state.mode, tint: .accentColor)
            }
        }
    }


    // MARK: - AlarmTitle

    @ViewBuilder
    private func alarmTitle(attributes: AlarmAttributes<CueAlarmAttributes>, state: AlarmPresentationState) -> some View {
        let title: LocalizedStringResource? = switch state.mode {
        case .countdown:
            attributes.presentation.countdown?.title
        case .paused:
            attributes.presentation.paused?.title
        default:
            nil
        }

        Text(title ?? "")
            .font(.title3)
            .fontWeight(.semibold)
            .lineLimit(1)
            .padding(.leading, 6)
    }


    // MARK: - ReminderAttribute

    @ViewBuilder
    private func reminderView(metadata: CueAlarmAttributes?) -> some View {
        if let metadata {
            HStack(alignment: .center, spacing: 8) {
                Image(uiImage: metadata.image(size: .init(width: 32, height: 32)))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                Text(metadata.title)
                    .font(.headline)
                    .fontWeight(.semibold)
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

struct AlarmProgressView: View {
    var icon: CueAlarmAttributes?
    var mode: AlarmPresentationState.Mode
    var tint: Color

    var body: some View {
        Group {
            switch mode {
            case .countdown(let countdown):
                ProgressView(
                    timerInterval: Date.now ... countdown.fireDate,
                    countsDown: true,
                    label: { EmptyView() },
                    currentValueLabel: {
                        if let icon {
                            Image(uiImage: icon.image(size: .init(width: 12, height: 12)))
                                .scaleEffect(0.9)
                        }
                    })
            case .paused(let pausedState):
                let remaining = pausedState.totalCountdownDuration - pausedState.previouslyElapsedDuration
                ProgressView(value: remaining,
                             total: pausedState.totalCountdownDuration,
                             label: { EmptyView() },
                             currentValueLabel: {
                    Image(systemName: "pause.fill")
                        .scaleEffect(0.8)
                })
            default:
                EmptyView()
            }
        }
        .progressViewStyle(.circular)
        .foregroundStyle(tint)
        .tint(tint)
    }
}
