//
//  NotificationManager.swift
//  Cue
//
//  Created by Krishna Venkatramani on 07/02/2026.
//

import Foundation
import NotificationCenter
import CoreData
import Combine

public class NotificationManager: NSObject, NotificationSchedulerDelegate {
    
    public typealias NotificationSettingsCompletion = (UNNotificationSettings) -> Void
    
    private(set) var notificationCenter = UNUserNotificationCenter.current()
    private(set) var scheduler: NotificationScheduler
    private  var context: NSManagedObjectContext
    private var subscribers: Set<AnyCancellable> = .init()
    var notificationSetting: UNNotificationSettings!
    
    var authorizationStatus: UNAuthorizationStatus {
        get { notificationSetting.authorizationStatus }
    }
    
    init(context: NSManagedObjectContext) {
        self.scheduler = .init(context: context)
        self.context = context
        super.init()
        self.scheduler.delegate = self
        requestForAuthorizationAfterCheckingNotificationSettings()
        observe()
    }
    
    public func getCurrentNotificationSettings() {
        fetchCurrentNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationSetting = settings
            }
        }
    }
    
    public func fetchCurrentNotificationSettings(_ completion: @escaping NotificationSettingsCompletion) {
        notificationCenter.getNotificationSettings(completionHandler: completion)
    }
    
    public func requestForAuthorizationAfterCheckingNotificationSettings(completion: NotificationSettingsCompletion? = nil) {
        // Check for notificationSettingsFirst first
        notificationCenter.getNotificationSettings { settings in
            print("(DEBUG) \(#function) settings: \(settings.authorizationStatus)")
            switch settings.authorizationStatus {
            case .authorized, .denied:
                DispatchQueue.main.async {
                    self.notificationSetting = settings
                    completion?(settings)
                }
            case .notDetermined:
                self.requestForAuthorization(completion: completion)
            case .ephemeral, .provisional:
                break
            @unknown default:
                fatalError()
            }
        }
    }
    
    public func requestForAuthorization(completion: NotificationSettingsCompletion? = nil) {
        notificationCenter.requestAuthorization(options: [.sound, .badge, .alert]) { [weak self] granted, error in
            if let error {
                print("(ERROR) Error while reqeusting for notification authorization: \(error.localizedDescription)")
            }
            
            guard granted else {
                print("(ERROR) Notification was not authorized")
                return
            }
            
            // Fetch Current Notification Setttings
            
            self?.notificationCenter.getNotificationSettings { settings in
                // Add any more action in the future
                print("(DEBUG) Authorization: \(settings.authorizationStatus)")
                DispatchQueue.main.async {
                    self?.notificationSetting = settings
                    completion?(settings)
                }
            }
        }
    }
    
    public func openSettings() {
        let url = URL(string: UIApplication.openSettingsURLString)
        guard let url else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { status in
                print("(DEBUG) Opening settings for app")
            }
        }
    }
    
    public func setupNotifications(_ reminders: [Reminder]) {
        let models = reminders.map { ReminderModel.init(from: $0) }
        scheduler.cleanUpHabitsReminders(reminders: models)
    }
    
    
    // MARK: - observe
    
    private func observe() {
        let deleteReminder = NotificationCenter.default.publisher(for: .deletedReminder).map { _ in () }.eraseToAnyPublisher()
        let updatedReminder = NotificationCenter.default.publisher(for: .updatedReminder).map { _ in () }.eraseToAnyPublisher()
        let addedReminder = NotificationCenter.default.publisher(for: .addedReminder).map { _ in () }.eraseToAnyPublisher()

        let changePublisher = Publishers.Merge3(deleteReminder, updatedReminder, addedReminder).eraseToAnyPublisher()
        
        let appOpen = NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification).map { _ in () }.eraseToAnyPublisher()

        changePublisher
            .map { _ in
                let reminders = Reminder.fetchAll(context: self.context).map { ReminderModel(from: $0) }
                return reminders
            }
            .sink { [weak self] reminders in
                self?.setupReminders(reminders: reminders)
            }
            .store(in: &subscribers)
        
        //        appOpen
        //            .withUnretained(self)
        //            .map { (manager, _) in
        //                let habits = HabitModel.fetchHabits().map { $0.toSimpleHabit() }
        //                return habits != manager.habits
        //            }
        //            .filter { $0 }
        //            .withUnretained(self)
        //            .sinkReceive { (manager, _) in
        //                manager.habits = HabitModel.fetchHabits().map { $0.toSimpleHabit() }
        //                manager.cleanUpHabitsReminders()
        //            }
        //            .store(in: &bag)
    }
    
    private func setupReminders(reminders: [ReminderModel]) {
//        let reminders = Reminder.fetchAll(context: self.context).map { ReminderModel(from: $0) }
        scheduler.cleanUpHabitsReminders(reminders: reminders)
    }
    
    
    // MARK: - NotificationSchedulerDelegate
    
    func removeAllPendingNotificationRequests() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func removePendingNotificationRequests(withIdentifiers: [String]) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: withIdentifiers)
    }
    
    func add(_ request: UNNotificationRequest, completion: @escaping ((any Error)?) -> Void) {
        notificationCenter.add(request, withCompletionHandler: completion)
    }
}
