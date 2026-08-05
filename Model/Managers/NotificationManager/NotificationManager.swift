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

protocol NotificationManagerDelegate {
    func updateNotificationSettings(_ authorizationStatus: UNAuthorizationStatus)
}

public class NotificationManager: NSObject, NotificationSchedulerDelegate {
    
    public typealias NotificationSettingsCompletion = (UNNotificationSettings) -> Void
    
    private(set) var notificationCenter = UNUserNotificationCenter.current()
    private(set) var scheduler: NotificationScheduler
    private  var context: NSManagedObjectContext
    private var subscribers: Set<AnyCancellable> = .init()
    
    var delegate: NotificationManagerDelegate?
    var notificationSetting: UNNotificationSettings! {
        didSet {
            delegate?.updateNotificationSettings(notificationSetting.authorizationStatus)
        }
    }
    
    var authorizationStatus: UNAuthorizationStatus {
        get { notificationSetting.authorizationStatus }
    }
    
    init(context: NSManagedObjectContext) {
        self.scheduler = .init(context: context)
        self.context = context
        super.init()
        self.scheduler.delegate = self
        getCurrentNotificationSettings()
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
    
    @MainActor
    @discardableResult
    public func requestForAuthorizationAfterCheckingNotificationSettings() async -> Bool {
        let settings = await notificationCenter.notificationSettings()
        print("(DEBUG) \(#function) settings: \(settings.authorizationStatus)")
        switch settings.authorizationStatus {
        case .authorized, .denied:
            self.notificationSetting = settings
            return true
        case .notDetermined:
            do {
                try await notificationCenter.requestAuthorization(options: [.sound, .badge, .sound])
                return await self.requestForAuthorizationAfterCheckingNotificationSettings()
            } catch {
                print("(ERROR) Error while reqeusting for notification authorization: \(error.localizedDescription)")
                return false
            }
        case .ephemeral, .provisional:
            return false
        @unknown default:
            fatalError()
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
        Publishers.Merge(
            NotificationCenter.default.publisher(for: .addedReminder),
            NotificationCenter.default.publisher(for: .updatedReminder)
        )
        .compactMap(\.reminderModel)
        .sink { [weak self] reminder in
            guard let self else { return }
            if reminder.notificationType == .notification {
                scheduler.scheduleNotificationForReminder(reminder: reminder)
            } else {
                scheduler.removeNotifications(for: reminder)
            }
        }
        .store(in: &subscribers)

        NotificationCenter.default.publisher(for: .deletedReminder)
            .compactMap(\.reminderModel)
            .sink { [weak self] reminder in
                self?.scheduler.removeNotifications(for: reminder)
            }
            .store(in: &subscribers)
    }
    
    private func setupReminders(reminders: [ReminderModel]) {
//        let reminders = Reminder.fetchAll(context: self.context).map { ReminderModel(from: $0) }
        scheduler.cleanUpHabitsReminders(reminders: reminders)
    }
    
    
    // MARK: - Updates From Store
    
    public func disableNotifications() {
        removeAllPendingNotificationRequests()
    }
    
    public func enableNotifications() {
        let reminders = Reminder.fetchRemindersWithNotification(context: self.context).map { ReminderModel(from: $0) }
        self.setupReminders(reminders: reminders)
    }
    
    
    // MARK: - NotificationSchedulerDelegate
    
    func removeAllPendingNotificationRequests() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func removePendingNotificationRequests(withIdentifiers: [String]) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: withIdentifiers)
    }
    
    func pendingNotifications() async -> [UNNotificationRequest] {
        await notificationCenter.pendingNotificationRequests()
    }
    
    func add(_ request: UNNotificationRequest, completion: @escaping ((any Error)?) -> Void) {
        notificationCenter.add(request, withCompletionHandler: completion)
    }
}
