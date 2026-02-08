//
//  KyuLiveActivityLiveActivity.swift
//  KyuLiveActivity
//
//  Created by Krishna Venkatramani on 08/02/2026.
//

import ActivityKit
import WidgetKit
import SwiftUI
//import Model
//
//struct AlarmLiveActivity: Widget {
//
//    var body: some WidgetConfiguration {
//        ActivityConfiguration(for: AlarmAttributes<CueAlarmAttributes>.self) { context in
//            VStack(alignment: .leading) {
//                HStack(alignment: .top) {
//                    alarmTitle(attributes: context.attributes, state: context.state)
//                    Spacer()
//                    reminderView(metadata: context.attributes.metadata)
//                }
//                countdown(state: context.state)
//            }
//        } dynamicIsland: { context in
//            DynamicIsland {
//                //Exapanded
//
//                DynamicIslandExpandedRegion(.leading) {
//                    alarmTitle(attributes: context.attributes, state: context.state)
//                }
//
//                DynamicIslandExpandedRegion(.trailing) {
//                    reminderView(metadata: context.attributes.metadata)
//                }
//
//                DynamicIslandExpandedRegion(.bottom) {
//                    countdown(state: context.state)
//                }
//            } compactLeading: {
//                countdown(state: context.state)
//            } compactTrailing: {
//                AlarmProgressView(icon: context.attributes.metadata!, mode: context.state.mode, tint: .accentColor)
//            } minimal: {
//                AlarmProgressView(icon: context.attributes.metadata!, mode: context.state.mode, tint: .accentColor)
//            }
//
//        }
//
//    }
//
//
//    // MARK: - AlarmTitle
//
//    @ViewBuilder func alarmTitle(attributes: AlarmAttributes<CueAlarmAttributes>, state: AlarmPresentationState) -> some View {
//        let title: LocalizedStringResource? = switch state.mode {
//        case .countdown:
//            attributes.presentation.countdown?.title
//        case .paused:
//            attributes.presentation.paused?.title
//        default:
//            nil
//        }
//
//        Text(title ?? "")
//            .font(.title3)
//            .fontWeight(.semibold)
//            .lineLimit(1)
//            .padding(.leading, 6)
//    }
//
//
//    // MARK: - ReminderAttibute
//
//    @ViewBuilder
//    func reminderView(metadata: CueAlarmAttributes?) -> some View {
//        if let metadata {
//            HStack(alignment: .center, spacing: 8) {
//                Image(uiImage: metadata.image(size: .init(width: 32, height: 32)))
//                    .resizable()
//                    .scaledToFit()
//                Text(metadata.title)
//                    .font(.headline)
//                    .fontWeight(.semibold)
//            }
//        } else {
//            EmptyView()
//        }
//    }
//
//
//    // MARK: - Countdown View
//
//    func countdown(state: AlarmPresentationState, maxWidth: CGFloat = .infinity) -> some View {
//        Group {
//            switch state.mode {
//            case .countdown(let countdown):
//                Text(timerInterval: Date.now ... countdown.fireDate, countsDown: true)
//            case .paused(let state):
//                let remaining = Duration.seconds(state.totalCountdownDuration - state.previouslyElapsedDuration)
//                let pattern: Duration.TimeFormatStyle.Pattern = remaining > .seconds(60 * 60) ? .hourMinuteSecond : .minuteSecond
//                Text(remaining.formatted(.time(pattern: pattern)))
//            default:
//                EmptyView()
//            }
//        }
//        .monospacedDigit()
//        .lineLimit(1)
//        .minimumScaleFactor(0.6)
//        .frame(maxWidth: maxWidth, alignment: .leading)
//    }
//
//}
//
//struct AlarmProgressView: View {
//    var icon: CueAlarmAttributes
//    var mode: AlarmPresentationState.Mode
//    var tint: Color
//
//    var body: some View {
//        Group {
//            switch mode {
//            case .countdown(let countdown):
//                ProgressView(
//                    timerInterval: Date.now ... countdown.fireDate,
//                    countsDown: true,
//                    label: { EmptyView() },
//                    currentValueLabel: {
//                        Image(uiImage: icon.image(size: .init(width: 12, height: 12)))
//                            .scaleEffect(0.9)
//                    })
//            case .paused(let pausedState):
//                let remaining = pausedState.totalCountdownDuration - pausedState.previouslyElapsedDuration
//                ProgressView(value: remaining,
//                             total: pausedState.totalCountdownDuration,
//                             label: { EmptyView() },
//                             currentValueLabel: {
//                    Image(systemName: "pause.fill")
//                        .scaleEffect(0.8)
//                })
//            default:
//                EmptyView()
//            }
//        }
//        .progressViewStyle(.circular)
//        .foregroundStyle(tint)
//        .tint(tint)
//    }
//}
////
////
////struct AlarmControls: View {
////    var presentation: AlarmPresentation
////    var state: AlarmPresentationState
////
////    var body: some View {
////        HStack(spacing: 4) {
////            switch state.mode {
////            case .countdown:
////                ButtonView(config: presentation.countdown?.pauseButton, intent: PauseIntent(alarmID: state.alarmID.uuidString), tint: .orange)
////            case .paused:
////                ButtonView(config: presentation.paused?.resumeButton, intent: ResumeIntent(alarmID: state.alarmID.uuidString), tint: .orange)
////            default:
////                EmptyView()
////            }
////
////            ButtonView(config: presentation.alert.stopButton, intent: StopIntent(alarmID: state.alarmID.uuidString), tint: .red)
////        }
////    }
////}
////
////struct ButtonView<I>: View where I: AppIntent {
////    var config: AlarmButton
////    var intent: I
////    var tint: Color
////
////    init?(config: AlarmButton?, intent: I, tint: Color) {
////        guard let config else { return nil }
////        self.config = config
////        self.intent = intent
////        self.tint = tint
////    }
////
////    var body: some View {
////        Button(intent: intent) {
////            Label(config.text, systemImage: config.systemImageName)
////                .lineLimit(1)
////        }
////        .tint(tint)
////        .buttonStyle(.borderedProminent)
////        .frame(width: 96, height: 30)
////    }
////}
