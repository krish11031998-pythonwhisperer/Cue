//
//  FocusTimerAlarmCoordinator.swift
//  VaneUI
//
//  Created by Krishna Venkatramani on 08/08/2026.
//

internal import AlarmKit
import SwiftUI
import VanorUI
import FamilyControls
import Model

@MainActor
protocol FocusTimerAlarmCoordinator {
    func scheduleAlarmForTimer(startDate: Date, timeInterval: TimeInterval, title: String, color: Color) async -> (UUID, Alarm)?
    func cancelAlarm(_ uuid: UUID)
    func requestAuthorization() async -> Bool
    func authorizationStatus() async -> AlarmManager.AuthorizationState
}

@MainActor
protocol FocusTimerLiveActivityCoordinator {
    func setupLiveActivity(for activityID: UUID, sessionAttributes: FocusSessionAttributes, startDate: Date, endDate: Date)
    func endLiveActivity(for activityID: UUID)
    func updateLiveAcitivity(for activityID: UUID, content: FocusSessionLiveActivityAttributes.ContentState)
}


@MainActor
protocol StoreCoordinator: AnyObject {
    var store: Store? { get set }
    var reminder: ReminderModel? { get set }
    var reminderTasks: [ReminderTaskModel] { get }
    var completedTasks: [ReminderTaskModel] { get set }
    var sessionAttributes: FocusSessionAttributes? { get }
    func saveTask(_ task: ReminderTaskModel) async
    func logReminder()
}
