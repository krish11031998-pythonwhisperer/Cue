//
//  CreateReminderViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 18/01/2026.
//

import SwiftUI
import VanorUI
import Model
import CoreData
import FoundationModels
internal import AlarmKit

@Observable
class CreateReminderViewModel: CreateReminderManager {
    
    enum Mode: Equatable {
        case create
        case edit(ReminderModel)
    }
    
    enum ReminderCalendarPresentation: String, Identifiable {
        case alarmAt = "Alarm At"
        case duration = "Duration"
        case date = "Date"
        case `repeat` = "Repeat"
        case iconSelector = "Symbol And Color"
        
        var id: String { self.rawValue }
        
        static var allCases: [ReminderCalendarPresentation] { [.alarmAt, .duration, .date, .repeat] }
    }
    
    enum Presentation: String, Identifiable {
        case tags
        
        var id: String { self.rawValue }
    }
    
    
    @ObservationIgnored
    var store: Store
    @ObservationIgnored
    lazy var reminderSubtasksSession: ReminderSubtaskSession = .init()
    @ObservationIgnored
    var suggestionTask: Task<Void, Never>?
    @ObservationIgnored
    var edittingMode: Bool
    @ObservationIgnored
    var reminderID: NSManagedObjectID?
    
    var imageFrame: CGRect = .zero
    var reminderTitle: String
    var snoozeDuration: Double
    var reminderNotification: ReminderNotification
    var date: Date
    var timeDate: Date
    var tasks: [CreateReminderTask]
    var tags: [TagModel]
    var scheduleBuilder: Reminder.ScheduleBuilder
    var icon: Icon
    var color: Color
    var isLoadingSuggestions: Bool = false
    var calendarPresentation: ReminderCalendarPresentation? = nil
    var presentation: Presentation? = nil
    
    private init(store: Store, suggestionTask: Task<Void, Never>? = nil, edittingMode: Bool, reminderID: NSManagedObjectID? = nil, reminderTitle: String, snoozeDuration: Double, reminderNotification: ReminderNotification, date: Date, timeDate: Date, tasks: [CreateReminderTask], tags: [TagModel], scheduleBuilder: Reminder.ScheduleBuilder, icon: Icon, color: Color) {
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
        self.color = color
    }
    
    convenience init(store: Store, mode: Mode) {
        switch mode {
        case .create:
            self.init(store: store, edittingMode: false, reminderTitle: "", snoozeDuration: 15 * 60, reminderNotification: .notification, date: .now, timeDate: .now, tasks: [], tags: [], scheduleBuilder: .init(.now), icon: .symbol(SFSymbol.allSymbols.randomElement()!), color: .proSky.baseColor)
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
            self.init(store: store, edittingMode: true, reminderID: reminderModel.objectId, reminderTitle: reminderModel.title, snoozeDuration: reminderModel.snoozeDuration, reminderNotification: reminderModel.notificationType, date: reminderModel.date, timeDate: timeDate, tasks: [], tags: [], scheduleBuilder: scheduleBuilder, icon: icon, color: .proSky.baseColor)
        }
    }
    
    var theme: LCHColor {
        .init(color: color)
    }
    
    func buttonTitleForElement(_ presentation: ReminderCalendarPresentation) -> String {
        switch presentation {
        case .alarmAt:
            timeString
        case .duration:
            durationString
        case .date:
            dateString
        case .repeat:
            scheduleString
        case .iconSelector:
            fatalError("No Button with title for \(presentation.rawValue)")
        }
    }
    
    var tagString: String? {
        guard !tags.isEmpty else { return nil }
        let tagName = tags.reduce("", {
            if $0.isEmpty {
                return $1.name
            } else {
                return "\($0) • \($1.name)"
            }
        })
        
        return tagName
    }
    
    func presentIconSheet() {
        print("(DEBUG) tapped on icon!")
        self.calendarPresentation = .iconSelector
    }
}
