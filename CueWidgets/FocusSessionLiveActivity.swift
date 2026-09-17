//
//  FocusSessionLiveActivity.swift
//  Cue
//
//  Created by Krishna Venkatramani on 08/08/2026.
//

import WidgetKit
import SwiftUI
import ActivityKit
import VanorUI


struct FocusSessionLiveActivity: Widget {
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: FocusSessionLiveActivityAttributes.self) { context in
            // Lock Screen, StandBy and the Apple Watch Smart Stack all come through here.
            // `FocusSessionActivityContentView` picks the layout off `\.activityFamily`
            // and supplies the container background the last two need.
            FocusSessionActivityContentView(attributes: context.attributes,
                                            state: context.state,
                                            toggleIntent: ToggleFocusSessionIntent())
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    FocusDynamicExpandedView(attributes: context.attributes,
                                             state: context.state,
                                             toggleIntent: ToggleFocusSessionIntent())
                }
            } compactLeading: {
                Text.focusCountdown(interval: context.attributes.startDate...context.state.endDate,
                                    pausedAt: context.state.pausedAt,
                                    showsHours: true)
                    .font(.caption2)
                    .frame(idealWidth: 40, maxWidth: 75, alignment: .center)
            } compactTrailing: {
                FocusLiveActivitySessionIcon(context.attributes, state: context.state, viewType: .iconWithProgressMinimal)
            } minimal: {
                FocusLiveActivitySessionIcon(context.attributes, state: context.state, viewType: .iconWithProgressMinimal)
            }
        }
        .supplementalActivityFamilies([.small])
    }
}


#Preview("FocusSessionLiveActivity",
         as: .content,
         using: FocusSessionLiveActivityAttributes.previewableView()) {
    FocusSessionLiveActivity()
} contentStates: {
    FocusSessionLiveActivityAttributes.ContentState(restTime: 0,
                                                    endDate: Date.now.addingTimeInterval(100 * 60),
                                                    progress: 0.5,
                                                    completedTasks: 2,
                                                    pausedAt: nil,
                                                    pomodoroSessionState: nil)
    FocusSessionLiveActivityAttributes.ContentState(restTime: 0,
                                                    endDate: Date.now.addingTimeInterval(100 * 60),
                                                    progress: 0.5,
                                                    completedTasks: 2,
                                                    pausedAt: .now,
                                                    pomodoroSessionState: .init(currentSession: 1,
                                                                                totalSessions: 5,
                                                                                currentSessionStartDate: Date.now,
                                                                                currentSessionEndDate: Date.now.addingTimeInterval(25 * 60)))
    
}
