//
//  FocusSessionModel+ReminderModel_FocusSession.swift
//  Model
//
//  Created by Krishna Venkatramani on 11/10/2026.
//

import Foundation

public extension FocusSessionModel {
    init(reminderFocusSession: ReminderModel.FocusSession, with reminder: ReminderModel? = nil) {
        self.name = reminderFocusSession.name
        self.sessionType = reminderFocusSession.sessionType
        self.timerDuration = reminderFocusSession.timerDuration
        self.breakDuration = reminderFocusSession.breakDuration
        self.sessionCount = reminderFocusSession.sessionCount
        self.blockedApps = reminderFocusSession.blockedApps
        self.alarm = reminderFocusSession.alarm
        self.reminder = reminder
        self.imageFileName = nil
    }
}
