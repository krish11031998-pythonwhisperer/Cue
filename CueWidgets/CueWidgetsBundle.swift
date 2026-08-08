//
//  CueWidgetsBundle.swift
//  CueWidgets
//

import WidgetKit
import SwiftUI

@main
struct CueWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ReminderAlarmLiveActivity()
        FocusAlarmLiveActivity()
    }
}
