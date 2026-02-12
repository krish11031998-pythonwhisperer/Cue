//
//  Model.swift
//  Model
//
//  Created by Krishna Venkatramani on 17/01/2026.
//

import Foundation
import CoreData
internal import UserNotifications
import AlarmKit
import UIKit

@Observable
@MainActor public class Store: NotificationManagerDelegate, AlarmManagerDelegate {
    
    public var user: User? = nil
    public var reminders: [Reminder] = []
    public var tags: [CueTag] = []
    public var presentCreateReminder: Bool = false
    @ObservationIgnored
    public private(set) var notificationManager: NotificationManager
    @ObservationIgnored
    public private(set) var alarmManager: CueAlarmManager
    
    public var viewContext: NSManagedObjectContext {
        CoreDataManager.shared.persistentContainer.viewContext
    }
    
    public func backgroundContext() -> NSManagedObjectContext {
        CoreDataManager.shared.persistentContainer.newBackgroundContext()
    }
    
    public init() {
        self.notificationManager = .init(context: CoreDataManager.shared.persistentContainer.viewContext)
        self.alarmManager = .init(context: CoreDataManager.shared.persistentContainer.viewContext)
        self.retrieveUser()
        self.reminders = Reminder.fetchAll(context: self.viewContext)
        self.tags = CueTag.fetchAll(context: self.viewContext)
        self.notificationManager.delegate = self
        observingTask()
    }
    
    
    // MARK: - Binding
    
    private func observingTask() {
        let remindersChangeStream: AsyncStream<()> = self.viewContext.changesStream(for: Reminder.self, changeTypes: [.inserted, .deleted, .updated])
        let reminderTasksChangeStream: AsyncStream<()> = self.viewContext.changesStream(for: ReminderTask.self, changeTypes: [.inserted, .deleted, .updated])
        let tagsChangeStream: AsyncStream<()> = self.viewContext.changesStream(for: CueTag.self, changeTypes: [.inserted, .deleted, .updated])
        
        Task { @MainActor [weak self] in
            for await _ in remindersChangeStream {
                if let context = self?.viewContext {
                    let reminders = Reminder.fetchAll(context: context)
                    self?.reminders = reminders
                }
            }
        }
        
        Task { @MainActor [weak self] in
            for await _ in reminderTasksChangeStream {
                if let context = self?.viewContext {
                    let reminderTask = ReminderTask.fetchAll(context: context)
                }
            }
        }
        
        Task { @MainActor [weak self] in
            for await _ in tagsChangeStream {
                if let context = self?.viewContext {
                    let tags = CueTag.fetchAll(context: context)
                    self?.tags = tags
                }
            }
        }
    }
    
    public var hasLoggedReminder: AsyncStream<Void> {
        self.viewContext.changesStream(for: ReminderLog.self, changeTypes: [.inserted, .deleted, .updated])
    }
    
    public var hasLoggedTasks: AsyncStream<Void> {
        self.viewContext.changesStream(for: ReminderTaskLog.self, changeTypes: [.inserted, .deleted, .updated])
    }
    
    
    // MARK: - Create User
    
    @MainActor
    func retrieveUser() {
        let users = User.fetchAll(context: viewContext)
        if let firstUser = users.first {
            self.user = firstUser
        } else {
            let user = User.createUser(context: viewContext)
            viewContext.saveContext()
            self.user = user
        }
    }
    
    // MARK: - Reminders
    
    @discardableResult
    public func createReminder(title: String, icon: CueIcon, date: Date, snoozeDuration: TimeInterval, scheduleBuilder: Reminder.ScheduleBuilder?, tasks: [ReminderTaskModel] = [], reminderNotification: ReminderNotification, tags tagModels: [TagModel]) -> Reminder {
        let reminder = Reminder.createReminder(context: viewContext, title: title, icon: icon, date: date, snoozeDuration: snoozeDuration, schedule: scheduleBuilder, reminderNotification: reminderNotification)
        
        tasks.forEach { task in
            let reminderTask = fetchReminderTask(task.objectId)
            reminderTask.reminder = reminder
        }
        
        var tags: [CueTag] = []
        for tagModel in tagModels {
            let tag = fetchTag(tagModel.objectId)
            tags.append(tag)
        }
        
        reminder.updateTags(tags)
        
        viewContext.saveContext()
        NotificationCenter.default.post(name: .addedReminder, object: nil)
        return reminder
    }
    
    public func deleteReminder(reminderID: NSManagedObjectID) {
        let reminder = Reminder.fetch(context: viewContext, for: reminderID)
        reminder.delete(context: viewContext)
        NotificationCenter.default.post(name: .deletedReminder, object: nil)
    }
    
    public func updateReminder(for id: NSManagedObjectID, transform: (Reminder) -> Void) {
        let reminder = Reminder.fetch(context: viewContext, for: id)
        reminder.update(context: viewContext, transform: transform)
        NotificationCenter.default.post(name: .updatedReminder , object: nil)
    }
    
    public func updateTasksInReminder(reminder: Reminder, reminderTasks: [ReminderTaskModel], save: Bool) {
        reminder.removeTasks()
        for reminderTask in reminderTasks {
            let task = ReminderTask.fetch(context: viewContext, for: reminderTask.objectId)
            task.reminder = reminder
        }
        if save {
            viewContext.saveContext()
        }
    }
    
    public func updateTagsInReminder(reminder: Reminder, tags: [TagModel], save: Bool) {
        reminder.removeTags()
        var cueTags: [CueTag] = []
        for tagModel in tags {
            let tag = CueTag.fetch(context: viewContext, for: tagModel.objectId)
            cueTags.append(tag)
        }
        reminder.updateTags(cueTags)
        if save {
            viewContext.saveContext()
        }
    }
   
    
    // MARK: - ReminderLogs
    
    public func fetchReminderLogs(context: NSManagedObjectContext? = nil, from start: Date, to end: Date) -> [ReminderLog] {
        let viewContext = context ?? self.viewContext
        return ReminderLog.fetchLogsWithinTimeRange(context: viewContext, startTime: start, endTime: end) as? [ReminderLog] ?? []
    }
    
    @discardableResult
    public func logReminder(at date: Date, for reminderID: NSManagedObjectID) -> ReminderLog {
        let reminder = Reminder.fetch(context: viewContext, for: reminderID)
        let reminderLog = ReminderLog.createReminderLog(date: date, context: viewContext, reminder: reminder)
        return reminderLog
    }
    
    public func deleteLogsFor(at date: Date, for reminderID: NSManagedObjectID) {
        let reminder = Reminder.fetch(context: viewContext, for: reminderID)
        ReminderLog.deleteLog(at: date, reminder: reminder, context: viewContext)
    }
    
    
    // MARK: - ReminderTask
    
    @discardableResult
    public func createReminderTask(title: String, icon: CueIcon) -> ReminderTask {
        let reminderTask = ReminderTask.createTask(context: viewContext, title: title, icon: icon)
        viewContext.saveContext()
        return reminderTask
    }
    
    private func fetchReminderTask(_ reminderTaskID: NSManagedObjectID) -> ReminderTask {
        ReminderTask.fetch(context: viewContext, for: reminderTaskID)
    }
    
    public func updateReminderTask(for id: NSManagedObjectID, transform: (ReminderTask) -> Void) {
        let reminder = ReminderTask.fetch(context: viewContext, for: id)
        reminder.update(context: viewContext, transform: transform)
    }
    
    public func deleteReminderTask(reminderTaskID: NSManagedObjectID) {
        let reminder = ReminderTask.fetch(context: viewContext, for: reminderTaskID)
        reminder.delete(context: viewContext)
    }
    
    @discardableResult
    public func logReminderTask(at date: Date, for reminderTaskID: NSManagedObjectID, completion: ((Bool) -> Void)?) -> ReminderTaskLog {
        let reminderTask = ReminderTask.fetch(context: viewContext, for: reminderTaskID)
        let reminderLog = ReminderTaskLog.createReminderTaskLog(date: date, context: viewContext, reminderTask: reminderTask)
        viewContext.saveContext(with: completion)
        return reminderLog
    }
    
    public func deleteTaskLogsFor(at date: Date, for reminderTaskID: NSManagedObjectID, completion: ((Bool) -> Void)?) {
        let reminderTask = ReminderTask.fetch(context: viewContext, for: reminderTaskID)
        ReminderTaskLog.deleteLog(at: date, reminderTask: reminderTask, context: viewContext)
        viewContext.saveContext(with: completion)
    }
    
    
    // MARK: - Tag
    
    @discardableResult
    public func createTag(name: String, color: UIColor) -> CueTag {
        let tag = CueTag.createTag(context: viewContext, name: name, color: color)
        viewContext.saveContext()
        return tag
    }
    
    public func deleteTag(for id: NSManagedObjectID) {
        let tag = CueTag.fetch(context: viewContext, for: id)
        tag.delete(context: viewContext)
        viewContext.saveContext()
    }
    
    public func fetchTag(_ id: NSManagedObjectID) -> CueTag {
        CueTag.fetch(context: viewContext, for: id)
    }
    
    
    // MARK: - User
    
    public func updateUser(transform: @escaping (User) -> Void) {
        user?.update(context: viewContext, transform: transform)
    }
    
    
    // MARK: - Enable Disable Notifications
    
    func enableNotifications() {
        if notificationManager.authorizationStatus == .notDetermined {
            notificationManager.requestForAuthorizationAfterCheckingNotificationSettings { [weak self] settings in
                guard settings.authorizationStatus == .authorized else { return }
                self?.notificationManager.enableNotifications()
            }
        } else if notificationManager.authorizationStatus != .denied {
            notificationManager.enableNotifications()
        }
    }
    
    func disableNotifications() {
        notificationManager.disableNotifications()
    }
    
    public func updateNotificationsAccess() {
        let currentState = user?.notificationEnabled ?? false
        if currentState {
            disableNotifications()
        } else {
            enableNotifications()
        }
        
        updateUser { user in
            user.notificationEnabled = !user.notificationEnabled
        }
    }
    
    
    // MARK: - Enable Disable Alarms
    
    func enableAlarms() {
        if alarmManager.authorizationState == .notDetermined {
            Task { @MainActor [weak self] in
                await self?.alarmManager.requestForAuthortization()
                guard self?.alarmManager.authorizationState == .authorized else { return }
                self?.alarmManager.enableAlarms()
            }
        } else {
            alarmManager.enableAlarms()
        }
    }
    
    func disableAlarms() {
        alarmManager.removeAllAlarms()
    }
    
    public func updateAlarmsAccess() {
        let currentState = user?.alarmEnabled ?? false
        if currentState {
            disableAlarms()
        } else {
            enableAlarms()
        }
        updateUser { user in
            user.alarmEnabled = !user.alarmEnabled
        }
    }
    
    
    // MARK: - NotificationManagerDelegate
    
    func updateNotificationSettings(_ authorizationStatus: UNAuthorizationStatus) {
        updateUser { user in
            user.notificationEnabled = authorizationStatus == .authorized
        }
    }
    
    func updateAlarmSettings(_ authorizationStatus: AlarmManager.AuthorizationState) {
        updateUser { user in
            user.alarmEnabled = authorizationStatus == .authorized
        }
    }
}


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
