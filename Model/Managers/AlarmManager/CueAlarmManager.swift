//
//  AlarmManager.swift
//  Model
//
//  Created by Krishna Venkatramani on 08/02/2026.
//

import Foundation
import AlarmKit
import SwiftUI
internal import ActivityKit
import CoreData
import Combine

fileprivate extension Locale.Weekday {
    init?(from int: Int) {
        switch int {
        case 1:
            self = .sunday
        case 2:
            self = .monday
        case 3:
            self = .tuesday
        case 4:
            self = .wednesday
        case 5:
            self = .thursday
        case 6:
            self = .friday
        case 7:
            self = .saturday
        default:
            return nil
        }
    }
}

public class CueAlarmManager {
    
    public private(set) var authorizationState: AlarmManager.AuthorizationState = .notDetermined
    private var context: NSManagedObjectContext
    private var alarmSchedulingTasks: Task<Void, Never>?
    private var subscribers: Set<AnyCancellable> = .init()
    
    private var alarmsMap = AlarmsMap()
    private let alarmManager = AlarmManager.shared
    typealias AlarmsMap = [UUID: Alarm]
    
    init(context: NSManagedObjectContext) {
        self.context = context
        checkAuthorization()
        observeReminderToSetAlarm()
        getCurrentAlarms()
    }
    
    func checkAuthorization() {
        switch alarmManager.authorizationState {
        case .notDetermined:
            authorizationState = .notDetermined
        case .denied:
            authorizationState = .authorized
        case .authorized:
            authorizationState = .denied
        @unknown default:
            break
        }
    }
    
    public func requestForAuthortization() async {
        do {
            let result = try await alarmManager.requestAuthorization()
            self.authorizationState = result
        } catch {
            print("(ERROR) there was an error while creating an Alarm")
        }
    }
    
    public static func scheduleAnAlarm(reminder: ReminderModel) async -> (UUID, Alarm)? {
        
        guard let schedule = reminder.schedule else { return nil }
        let hour = schedule.hour
        let minute = schedule.minute
        let weekdays = schedule.weekdays
        
        let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
        let alarmSchedule: Alarm.Schedule
        if let weekdays {
            let recurrence = Alarm.Schedule.Relative.Recurrence.weekly(weekdays.compactMap { .init(from: $0) })
            alarmSchedule = .relative(.init(time: time, repeats: recurrence))
        } else {
            var dateComponents = Calendar.current.dateComponents([.day, .month, .year], from: reminder.date)
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.calendar = .current
            print("(DEBUG) date: ", dateComponents.date!)
            alarmSchedule = .fixed(dateComponents.date!)
        }
        
        let id: UUID = reminder.notificationID
        
        let title = reminder.title
        let alert: AlarmPresentation.Alert
        if #available(iOS 26.1, *) {
            alert = AlarmPresentation.Alert(title: .init(stringLiteral: title), secondaryButton: .snoozeButton, secondaryButtonBehavior: .countdown)
        } else {
            alert = AlarmPresentation.Alert(title: .init(stringLiteral: title), stopButton: .stopButton, secondaryButton: .snoozeButton, secondaryButtonBehavior: .countdown)
        }
        
        
        let alarmPresentation = AlarmPresentation(alert: alert)
        
        let attributes = AlarmAttributes<CueAlarmAttributes>(presentation: alarmPresentation,
                                                             metadata: .init(icon: reminder.icon, title: reminder.title),
                                                             tintColor: Color.blue)
        
        let configuration = AlarmManager.AlarmConfiguration.init(countdownDuration: .init(preAlert: nil, postAlert: reminder.snoozeDuration * 60),
                                                                 schedule: alarmSchedule,
                                                                 attributes: attributes, stopIntent: nil, secondaryIntent: nil, sound: .default)
        
        do {
            let  alarm = try await AlarmManager.shared.schedule(id: id, configuration: configuration)
            print("(DEBUG) Successfully created an alarm \(alarm.id) ✅!")
            return (id, alarm)
        } catch {
            print("(ERROR) there was an error!\(error.self): ", error.localizedDescription)
        }
        
        return nil
    }
    
    
    // MARK: - Observe
    
    func getCurrentAlarms() {
        do {
            let alarms = try AlarmManager.shared.alarms
            alarms.forEach { alarm in
                alarmsMap[alarm.id] = alarm
            }
        } catch {
            print("(ERROR) error while retrieving alarms: ", error.localizedDescription)
        }
    }
    
    private func cancelAlarms(_ ids: [UUID]) {
        for id in ids {
            try? alarmManager.cancel(id: id)
            Task { @MainActor in
                self.alarmsMap.removeValue(forKey: id)
            }
        }
    }
    
    private func cleanUpAlarms() {
        guard let currentAlarms = try? alarmManager.alarms else { return }
        var alarmsToRemove: [UUID] = []
        currentAlarms.forEach { alarm in
            if alarmsMap[alarm.id] == nil {
                alarmsToRemove.append(alarm.id)
            }
        }
        cancelAlarms(alarmsToRemove)
        print("(DEBUG) allAlarms: \(alarmsMap.values)")
    }
    
    func observeReminderToSetAlarm() {
        let addedReminder = NotificationCenter.default.publisher(for: .addedReminder).map { _ in  () }.eraseToAnyPublisher()
        let updatedReminder = NotificationCenter.default.publisher(for: .updatedReminder).map { _ in  () }.eraseToAnyPublisher()
        let deletedReminder = NotificationCenter.default.publisher(for: .deletedReminder).map { _ in  () }.eraseToAnyPublisher()
    
        
        Publishers.Merge3(addedReminder, updatedReminder, deletedReminder)
            .compactMap { [weak self] _ -> [ReminderModel]? in
                guard let self else { return nil }
                let reminders = Reminder.fetchRemindersWithAlarm(context: self.context)
                return reminders.map { .init(from: $0) }
            }
            .sink { [weak self] reminders in
                self?.scheduleAlarmForReminder(reminders)
            }
            .store(in: &subscribers)
    }
    
    private func observeAlarms() {
        Task {
            for await incomingAlarms in alarmManager.alarmUpdates {
                print("(DEBUG) incomingAlarms: ", incomingAlarms)
            }
        }
    }
    
//    private func updateAlarmState(with remoteAlarms: [Alarm]) {
//        Task { @MainActor in
//            
//            // Update existing alarm states.
//            remoteAlarms.forEach { updated in
//                alarmsMap[updated.id] = updated
//            }
//            
//            let knownAlarmIDs = Set(alarmsMap.keys)
//            let incomingAlarmIDs = Set(remoteAlarms.map(\.id))
//            
//            // Clean-up removed alarms.
//            let removedAlarmIDs = Set(knownAlarmIDs.subtracting(incomingAlarmIDs))
//            removedAlarmIDs.forEach {
//                alarmsMap[$0] = nil
//            }
//        }
//    }
    
    
    private func checkAlarmIsvalidForReminderSchedule(_ reminderSchedule: ReminderSchedule, schedule: Alarm.Schedule) -> Bool {
        switch schedule {
        case .fixed(let date):
            return date.hours == reminderSchedule.hour && date.minutes == reminderSchedule.minute
        case .relative(let relative):
            let timeIsValid = relative.time.hour == reminderSchedule.hour && relative.time.minute == reminderSchedule.minute
            guard let weekdays = reminderSchedule.weekdays,
                  case .weekly(let weekdayRecurrence) = relative.repeats else {
                return timeIsValid
            }
            
            let localeWeekdays: Set<Locale.Weekday> = Set(weekdays.compactMap { Locale.Weekday(from: $0) }).subtracting(Set(weekdayRecurrence))
            
            return timeIsValid && localeWeekdays.isEmpty
        @unknown default:
            return false
        }
    }
    
    private func scheduleAlarmForReminder(_ reminders: [ReminderModel]) {
        
        let alarmsIDsFromReminders = reminders.map(\.notificationID)
        
        // Alarms which should be deleted sinc the reminders are deleted
        let danglingAlarms = Set(alarmsMap.keys).subtracting(alarmsIDsFromReminders)
        print("(DEBUG) danglingAlarms: ", danglingAlarms)
    
        // Reminders where we need to setup an alarm for !
        let remindersThatNeedAlarm = reminders.filter({ alarmsMap[$0.notificationID] == nil })
        print("(DEBUG) remindersThatNeedAlarm: ", remindersThatNeedAlarm)
    
        let remainingReminders = Set(reminders).subtracting(remindersThatNeedAlarm)
        
        
        let reminderThatNeedUpdates = remainingReminders.compactMap { reminderModel -> ReminderModel? in
            guard let alarm = alarmsMap[reminderModel.notificationID],
                  let schedule = alarm.schedule,
                  let reminderSchedule = reminderModel.schedule else { return nil }
            return checkAlarmIsvalidForReminderSchedule(reminderSchedule, schedule: schedule) ? nil : reminderModel
        }
        print("(DEBUG) reminderThatNeedUpdates: ", reminderThatNeedUpdates)
        
        // Cancelling alarms that need updates!
        cancelAlarms(reminderThatNeedUpdates.map(\.notificationID))
        
        alarmSchedulingTasks?.cancel()
        alarmSchedulingTasks = Task {
            let scheduledAlarms: [Alarm]
            if remindersThatNeedAlarm.isEmpty == false {
                scheduledAlarms = await withTaskGroup(of: Alarm?.self, returning: [Alarm].self) { group in
                    let addTasks = (remindersThatNeedAlarm + reminderThatNeedUpdates).reduce(true) { partialResult, reminderModel in
                        let wasAdded = group.addTaskUnlessCancelled {
                            guard let (_, alarm) = await Self.scheduleAnAlarm(reminder: reminderModel) else { return nil }
                            return alarm
                        }
                        return partialResult && wasAdded
                    }
                    
                    guard addTasks, !Task.isCancelled else { return [] }
                    
                    var alarms: [Alarm] = []
                    for await createdAlarm in group {
                        if let createdAlarm {
                            alarms.append(createdAlarm)
                        }
                    }
                    return alarms
                }
            } else {
                scheduledAlarms = []
            }
            
            await MainActor.run { [weak self] in
                danglingAlarms.forEach { id in
                    self?.alarmsMap[id] = nil
                }
                scheduledAlarms.forEach { alarm in
                    self?.alarmsMap[alarm.id] = alarm
                }
                self?.cleanUpAlarms()
            }
        }
    }
}
