//
//  NewCreateReminderViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 23/05/2026.
//

import SwiftUI
import VanorUI
import Model
import CoreData
import FoundationModels

@Observable
class NewCreateReminderViewModel: CreateReminderManager {
    
    enum Mode: Equatable {
        case create
        case edit(ReminderModel)
        case editFromAI(ReminderModel, (ReminderModel) -> Void)
        
        static func ==(lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.create, .create):
                return true
            case (.edit(let lhsReminder), .edit(let rhsReminder)):
                return lhsReminder == rhsReminder
            case (.editFromAI(let lhsReminder, _), editFromAI(let rhsReminder, _)):
                return lhsReminder == rhsReminder
            default:
                return false
            }
        }
    }
    
    enum Presentation: Identifiable {
        case emojiAndColorPicker
        case calendar
        case scheduleBuilder
        case snoozeDuration
        case remindMeDuration
        case timeSheet
        case tag
        
        var id: String {
            switch self {
            case .emojiAndColorPicker:
                return "emojiAndColorPicker"
            case .calendar:
                return "calendar"
            case .scheduleBuilder:
                return "scheduleBuilder"
            case .snoozeDuration:
                return "snoozeDuration"
            case .remindMeDuration:
                return "remindMeDuration"
            case .timeSheet:
                return "timeSheet"
            case .tag:
                return "tag"
            }
        }
    }
    
    @ObservationIgnored
    let mode: Mode
    @ObservationIgnored
    var store: Store
    @ObservationIgnored
    var emojiSession: EmojiSession = .init()
    @ObservationIgnored
    var reminderSubtasksSession: ReminderSubtaskSession = .init()
    @ObservationIgnored
    var suggestionTask: Task<Void, Never>?
    @ObservationIgnored
    var edittingMode: Bool = false
    @ObservationIgnored
    var reminderID: NSManagedObjectID?
    
    var reminderNotification: ReminderNotification = .notification
    
    var alarmIsOn: Bool {
        reminderNotification == .alarm
    }
    
    var imageFrame: CGRect = .zero
    var presentation: Presentation? = nil
    var reminderTitle: String = ""
    var snoozeDuration: Double = 15 * 60
    var date: Date = Date()
    var timeDate: Date = .init()
    var tags: [TagModel] = []
    var tasks: [CreateReminderTask] = []
    var scheduleBuilder: Reminder.ScheduleBuilder = .init(.now)
    var icon: Icon
    var colorModel: ColorModel = .init(color: .sky, colorName: "sky")
    var remindMeBefore: TimeInterval = 10 * 60
    var isLoadingSuggestions: Bool = false
    
    private init(store: Store, mode: Mode, suggestionTask: Task<Void, Never>? = nil, edittingMode: Bool, reminderID: NSManagedObjectID? = nil, reminderTitle: String, snoozeDuration: Double, reminderNotification: ReminderNotification, date: Date, timeDate: Date, tasks: [CreateReminderTask], tags: [TagModel], scheduleBuilder: Reminder.ScheduleBuilder, icon: Icon, colorModel: ColorModel) {
        self.mode = mode
        self.store = store
        self.suggestionTask = suggestionTask
        self.edittingMode = edittingMode
        self.reminderID = reminderID
        self.reminderTitle = reminderTitle
        self.snoozeDuration = snoozeDuration
        self.reminderNotification = reminderNotification
        self.date = date
        self.timeDate = timeDate
        self.tasks = tasks
        self.tags = tags
        self.scheduleBuilder = scheduleBuilder
        self.icon = icon
        self.colorModel = colorModel
    }
    
    convenience init(store: Store, mode: Mode) {
        switch mode {
        case .create:
            let colorModel = ColorModel(color: .sky, colorName: "sky")
            self.init(store: store, mode: mode, edittingMode: false, reminderTitle: "", snoozeDuration: 15 * 60, reminderNotification: .notification, date: .now, timeDate: .now, tasks: [], tags: [], scheduleBuilder: .init(.now), icon:  .emoji(Emoji.all.randomElement()!), colorModel: colorModel)
        case .edit(let reminderModel), .editFromAI(let reminderModel, _):
            let timeDate: Date
            let scheduleBuilder: Reminder.ScheduleBuilder
            if let schedule = reminderModel.schedule {
                timeDate = Calendar.current.date(bySettingHour: schedule.hour, minute: schedule.minute, second: 0, of: reminderModel.date) ?? .now
                scheduleBuilder = .init(hour: schedule.hour, minute: schedule.minute, intervalWeek: schedule.intervalWeeks, weekdays: schedule.weekdays, dates: schedule.calendarDates)
            } else {
                timeDate = .now
                scheduleBuilder = .init(intervalWeek: nil, weekdays: nil, dates: nil)
            }
            let icon: Icon = .init(reminderModel.icon) ?? .symbol(SFSymbol.allSymbols.randomElement()!)
            let reminderTasks: [CreateReminderTask] = reminderModel.tasks.compactMap { task -> CreateReminderTask? in
                guard let icon = Icon(task.icon) else { return nil }
                return .init(title: task.title, icon: icon, objectID: task.objectId)
            }
            let tags = reminderModel.tags
            let colorModel = ColorModel(color: reminderModel.color, colorName: reminderModel.colorName)
            self.init(store: store, mode: mode, edittingMode: true, reminderID: reminderModel.objectId, reminderTitle: reminderModel.title, snoozeDuration: reminderModel.snoozeDuration, reminderNotification: reminderModel.notificationType, date: reminderModel.date, timeDate: timeDate, tasks: reminderTasks, tags: tags, scheduleBuilder: scheduleBuilder, icon: icon, colorModel: colorModel)
        }
    }
    
    func reminderFromViewModel() -> ReminderModel {
        let icon: CueIcon = .from(icon)
        let tasks: [ReminderTaskModel] = tasks.map { .init(title: $0.title, icon: .from($0.icon)) }
        let schedule: ReminderSchedule = .init(hour: timeDate.hours, minute: timeDate.minutes, intervalWeeks: scheduleBuilder.intervalWeek, weekdays: scheduleBuilder.weekdays, calendarDates: scheduleBuilder.weekdays)
        
            return .init(notificationType: .notification,
                         title: reminderTitle,
                         icon: icon,
                         date: date,
                         snoozeDuration: snoozeDuration,
                         tasks: tasks,
                         tags: tags,
                         schedule: schedule,
                         colorName: colorModel.colorName)
    }
    
    var theme: LCHColor {
        .init(color: color)
    }
    
    func presentIconSheet() {
    }
    
    func saveReminder() async {
        switch reminderNotification {
        case .alarm:
            // Need to do the same for Alarm.
            await store.alarmManager.requestForAuthortization()
        case .notification:
            await store.notificationManager.requestForAuthorizationAfterCheckingNotificationSettings()
        default:
            break
        }
        if case .editFromAI(_, let action) = mode {
            action(reminderFromViewModel())
        } else {
            createReminder()
        }
    }
}
