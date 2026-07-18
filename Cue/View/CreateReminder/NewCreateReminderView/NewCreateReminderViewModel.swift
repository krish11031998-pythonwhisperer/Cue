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
    }
    
    enum Presentation: Identifiable {
        case emojiAndColorPicker
        case calendar
        case scheduleBuilder
        case snoozeDuration
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
            case .timeSheet:
                return "timeSheet"
            case .tag:
                return "tag"
            }
        }
    }
    
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
    @ObservationIgnored
    var reminderNotification: ReminderNotification = .notification
    
    var alarmIsOn: Bool = false {
        didSet {
            reminderNotification = alarmIsOn ? .alarm : .notification
        }
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
    var icon: Icon = .symbol(SFSymbol.allSymbols.randomElement()!)
    var colorModel: ColorModel = .init(color: .sky, colorName: "sky")
    var isLoadingSuggestions: Bool = false
    
    private init(store: Store, suggestionTask: Task<Void, Never>? = nil, edittingMode: Bool, reminderID: NSManagedObjectID? = nil, reminderTitle: String, snoozeDuration: Double, reminderNotification: ReminderNotification, date: Date, timeDate: Date, tasks: [CreateReminderTask], tags: [TagModel], scheduleBuilder: Reminder.ScheduleBuilder, icon: Icon, colorModel: ColorModel) {
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
            self.init(store: store, edittingMode: false, reminderTitle: "", snoozeDuration: 15 * 60, reminderNotification: .notification, date: .now, timeDate: .now, tasks: [], tags: [], scheduleBuilder: .init(.now), icon: .symbol(SFSymbol.allSymbols.randomElement()!), colorModel: colorModel)
        case .edit(let reminderModel):
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
            self.init(store: store, edittingMode: true, reminderID: reminderModel.objectId, reminderTitle: reminderModel.title, snoozeDuration: reminderModel.snoozeDuration, reminderNotification: reminderModel.notificationType, date: reminderModel.date, timeDate: timeDate, tasks: reminderTasks, tags: tags, scheduleBuilder: scheduleBuilder, icon: icon, colorModel: colorModel)
            self.alarmIsOn = reminderModel.notificationType == .alarm
        }
    }
    
    var theme: LCHColor {
        .init(color: color)
    }
    
    func presentIconSheet() {
    }
}
