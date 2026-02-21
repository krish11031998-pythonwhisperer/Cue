//
//  NotificationScheduler.swift
//  Cue
//
//  Created by Krishna Venkatramani on 07/02/2026.
//

import CoreData
import NotificationCenter
import Combine

internal protocol NotificationSchedulerDelegate: NSObject {
    var authorizationStatus: UNAuthorizationStatus { get }
    func removePendingNotificationRequests(withIdentifiers: [String])
    func add(_ request: UNNotificationRequest, completion: @escaping (Error?) -> Void)
    func removeAllPendingNotificationRequests()
}

public class NotificationScheduler: NSObject, UNUserNotificationCenterDelegate {
    
    private var bag: Set<AnyCancellable> = .init()
    private var reminders: [ReminderModel] = []
    private let context: NSManagedObjectContext
    weak var delegate: NotificationSchedulerDelegate?
    
    public init(context: NSManagedObjectContext) {
        self.context = context
        super.init()
        setup()
    }
    
    public func setup() {
        self.reminders = Reminder.fetchAll(context: context).map { ReminderModel(from: $0) }
    }
    
    public func scheduleNotificationForReminder(reminder: ReminderModel) {
    
        guard let authorization = delegate?.authorizationStatus,
                authorization == .authorized else { return }
        
        
        let id = reminder.notificationID.uuidString
        var identifiers: [String] = []
        var notificationRequests: [UNNotificationRequest] = []
  
        guard let reminderSchedule = reminder.schedule else { return }
        let triggersWithId: [(String, UNCalendarNotificationTrigger)]
        // Weekly
        if let weekInterval = reminderSchedule.intervalWeeks,
           let weekdays = reminderSchedule.weekdays
        {
            triggersWithId = triggers(startDate: reminder.date,
                                      hour: reminderSchedule.hour,
                                      minute: reminderSchedule.minute,
                                      for: Array(weekdays),
                                      intervalWeeks: weekInterval,
                                      prefixID: id)
            
        } else if let calendarDates = reminderSchedule.calendarDates {
            triggersWithId = triggersForCalendarDate(startDate: reminder.date, hour: reminderSchedule.hour, minute: reminderSchedule.minute, calendarDates: Array(calendarDates), prefixID: id)
        } else {
            var dateComponents = DateComponents()
            dateComponents.day = reminder.date.day
            dateComponents.month = reminder.date.month
            dateComponents.year = reminder.date.year
            dateComponents.weekOfYear = reminder.date.weekOfYear
            dateComponents.hour = reminderSchedule.hour
            dateComponents.minute = reminderSchedule.minute
            dateComponents.calendar = .autoupdatingCurrent
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            triggersWithId = [("\(id)_\(dateComponents)", trigger)]
        }
        
        for (id, trigger) in triggersWithId {
            identifiers.append(id)
            let notifiationContent = UNMutableNotificationContent()
            notifiationContent.title = reminder.title
            notifiationContent.sound = .default
            notificationRequests.append(.init(identifier: id,
                                              content: notifiationContent,
                                              trigger: trigger))
        }
        
        delegate?.removePendingNotificationRequests(withIdentifiers: identifiers)
        
        notificationRequests.forEach { notificationRequest in
            delegate?.add(notificationRequest) { error in
                if let error {
                    print("(ERROR) Adding Notification for the Reminder: \(reminder.title): \(error.localizedDescription)")
                } else {
                    print("(DEBUG) added a notification for \(notificationRequest.identifier) - \((notificationRequest.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate())")
                }
            }
        }
    }
    
    func updateReminders() {
        let reminders = Reminder.fetchAll(context: context).map { ReminderModel(from: $0) }
        self.reminders = reminders
    }
    
    func cleanUpHabitsReminders(reminders: [ReminderModel]) {
        delegate?.removeAllPendingNotificationRequests()
    
        print("(DEBUG) Add Notifications for current reminders!")
        
        reminders.forEach { reminder in
            scheduleNotificationForReminder(reminder: reminder)
        }
    }
    
    
    // MARK: - UNUserNotificationCenterDelegate
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.sound, .banner]
    }
    
    
    // MARK: - Calendar
    
    private func triggers(startDate: Date, hour: Int, minute: Int, for weekdays: [Int], intervalWeeks: Int, prefixID: String) -> [(String, UNCalendarNotificationTrigger)] {
        var triggers: [(String, UNCalendarNotificationTrigger)] = []
        if intervalWeeks == 1 {
            weekdays.forEach { weekday in
                let weekdayTrigger = triggerForWeekday(hour: hour, minute: minute, weekday: weekday, week: nil, prefixID: prefixID)
                triggers.append(weekdayTrigger)
            }
        } else {
            var currentWeek = startDate.weekOfYear
            let weeksInYear = currentWeek + 4//Calendar.autoupdatingCurrent.range(of: .weekOfYear, in: .yearForWeekOfYear, for: .now)!.count
            while currentWeek <= weeksInYear {
                print("(DEBUG) currentWeek: ", currentWeek)
                weekdays.forEach { weekday in
                    var (id, trigger) = triggerForWeekday(hour: hour, minute: minute, weekday: weekday, week: currentWeek, prefixID: prefixID, repeats: false)
                    id += "_\(currentWeek)"
                    triggers.append((id, trigger))
                }
                currentWeek += intervalWeeks
            }
        }
        
        return triggers
    }
    
    private func triggerForWeekday(hour: Int, minute: Int, weekday: Int, week: Int?, prefixID: String, repeats: Bool = true) -> (String, UNCalendarNotificationTrigger) {
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.weekday = weekday
        if let week {
            dateComponents.weekOfYear = week
            dateComponents.yearForWeekOfYear = Calendar.current.component(.year, from: Date.now)
        }
        dateComponents.calendar = .autoupdatingCurrent
            
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
        
        let id = "\(prefixID)_\(Calendar.current.shortWeekdaySymbols[weekday - 1])"
        
        return (id, trigger)
    }
    
    
    private func triggersForCalendarDate(startDate: Date, hour: Int, minute: Int, calendarDates: [Int], prefixID: String) -> [(String, UNCalendarNotificationTrigger)] {
        var triggers: [(String, UNCalendarNotificationTrigger)] = []
        for calendarDay in calendarDates {
            var dateComponents = DateComponents()
            dateComponents.hour = hour
            dateComponents.minute = minute
            dateComponents.day = calendarDay
            dateComponents.calendar = .autoupdatingCurrent
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let id = "\(prefixID)_\(calendarDay)"
            triggers.append((id, trigger))
        }
        
        return triggers
    }
    
}


internal class CueCalendarWeektIntervalNotificationTrigger: UNCalendarNotificationTrigger {
    
    enum Frequency {
        case once(Date)
        case weekly(Int, Int)
        case everyMonth(Int)
    }
    
    private var hour: Int
    private var mintue: Int
    private var interval: Int
    private var weekday: Int
//    private var frequency: Frequency
//    private var startDate: Date
    private var recentDate: Date
    
//    override init(dateMatching components: DateComponents, repeats: Bool) {
//        super.init(dateMatching: dateComponents, repeats: repeats)
//    }
    
//    init(startDate: Date, frequency: Frequency, repeats: Bool) {
//        self.startDate = startDate
//        self.recentDate = startDate
//        self.frequency = frequency
////        super.init(dateMatching: DateComponents(), repeats: repeats)
//        super.init(dateMatching: Calendar.current.dateComponents([.day, .month, .year, .weekday], from: startDate), repeats: repeats)
//    }
    
//    static func create(startDate: Date, frequency: Frequency, repeats: Bool) -> CueCalendarWeektIntervalNotificationTrigger {
//        var dateComponents = DateComponents()
//        dateComponents.hour = startDate.hours
//        dateComponents.minute = startDate.minutes
//        switch frequency {
//        case .once(let date):
//            dateComponents = Calendar.current.dateComponents([.day, .month, .year, .hour, .minute], from: date)
//        case .weekly(let weekday, _):
//            dateComponents.weekday = weekday
//        case .everyMonth(let int):
//            dateComponents.day = int
//        }
//        let trigger = CueCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)
//        trigger.frequency = frequency
//        trigger.startDate = startDate
//        trigger.recentDate = startDate
//        return trigger
//    }
    
    static func create(hour: Int, weekday: Int, week: Int, minute: Int, interval: Int) -> CueCalendarWeektIntervalNotificationTrigger {
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.weekday = weekday
        dateComponents.weekOfYear = week
        dateComponents.yearForWeekOfYear = Date.now.year
        dateComponents.calendar = .current
        let trigger = CueCalendarWeektIntervalNotificationTrigger(dateMatching: dateComponents, repeats: true)
//        trigger.frequency = .weekly(interval, 0)
//        trigger.startDate = Date()
        if let date = dateComponents.date {
            trigger.recentDate = date
        }
        trigger.hour = hour
        trigger.mintue = minute
        trigger.weekday = weekday
        return trigger
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func updateRecentDate() {
        let newDate: Date?
        newDate = Calendar.current.date(byAdding: .weekOfYear, value: interval, to: recentDate, wrappingComponents: true)
//        switch frequency {
//        case .once:
//            return
//        case .weekly(_, let interval):
//        case .everyMonth(_):
//            newDate = Calendar.current.date(byAdding: .month, value: 1, to: recentDate, wrappingComponents: true)
//        }
        if let newDate {
            self.recentDate = newDate
        }
    }
    
//    override var dateComponents: DateComponents {
//        var dateComponents = DateComponents()
//        dateComponents.hour = startDate.hours
//        dateComponents.minute = startDate.minutes
//        switch frequency {
//        case .once(_):
//            break
//        case .weekly(let int, _):
//            dateComponents.weekOfYear = recentDate.weekOfYear
//            dateComponents.weekday = int
//        case .everyMonth(let int):
//            dateComponents.month = recentDate.month
//            dateComponents.day = int
//        }
//        
//        return dateComponents
//    }
    
    override func nextTriggerDate() -> Date? {
        let date = recentDate
        updateRecentDate()
        return date
//        let date = recentDate.date
//        print("(DEBUG) date", date)
//        return date
    }
    
}
