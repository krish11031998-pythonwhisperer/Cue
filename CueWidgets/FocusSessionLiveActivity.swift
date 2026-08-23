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
            FocusSessionLockScreenLiveActivityView(attributes: context.attributes)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.bottom) {
                    FocusDynamicExpandedView(attributes: context.attributes)
                }
            } compactLeading: {
                Text(timerInterval: context.attributes.startDate...context.state.endDate, countsDown: true)
                    .font(.caption2)
                    .frame(idealWidth: 40, maxWidth: 75, alignment: .center)
            } compactTrailing: {
                FocusLiveActivitySessionIcon(context.attributes, viewType: .iconWithProgressMinimal)
            } minimal: {
                FocusLiveActivitySessionIcon(context.attributes, viewType: .iconWithProgressMinimal)
            }
        }.supplementalActivityFamilies([.small])
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
                                                    isPaused: false)
    
}
