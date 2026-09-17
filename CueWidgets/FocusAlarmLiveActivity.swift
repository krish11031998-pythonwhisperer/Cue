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
            // Lock Screen, StandBy and the Apple Watch Smart Stack all come through here;
            // `FocusAlarmActivityContentView` picks the layout off `\.activityFamily`.
            FocusAlarmActivityContentView(attributes: context.attributes, state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(alignment: .center, spacing: 8) {
                        FocusAlarmSessionIcon(metadata: context.attributes.metadata,
                                              tint: context.attributes.tintColor,
                                              size: 24)
                        FocusAlarmSessionTitle(metadata: context.attributes.metadata)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    FocusAlarmCountdown(state: context.state, maxWidth: 80)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    FocusAlarmSessionSubtitle(metadata: context.attributes.metadata)
                }
            } compactLeading: {
                FocusAlarmSessionIcon(metadata: context.attributes.metadata,
                                      tint: context.attributes.tintColor,
                                      size: 18)
            } compactTrailing: {
                FocusAlarmCountdown(state: context.state, maxWidth: 50)
            } minimal: {
                FocusAlarmSessionIcon(metadata: context.attributes.metadata,
                                      tint: context.attributes.tintColor,
                                      size: 18)
            }
        }
        // Without this the alarm activity never reaches the watch's Smart Stack at all -
        // `.medium` (the phone) is the only family a configuration advertises by default.
        .supplementalActivityFamilies([.small])
    }
}
