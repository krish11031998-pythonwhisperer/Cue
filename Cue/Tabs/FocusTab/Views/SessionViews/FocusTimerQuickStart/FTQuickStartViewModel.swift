//
//  FTQuickStartViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 21/06/2026.
//

import Foundation
import Model
import VanorUI
import SwiftUI
import FamilyControls
import ManagedSettings

@MainActor
@Observable
class FTQuickStartViewModel {
    
    static let translationsXThreshold: CGFloat = 100
    
    enum Sheet: Identifiable {
        case pomodoroSessionEditor
        case appBlock(Callback?)
        
        var id: String {
            switch self {
            case .pomodoroSessionEditor:
                return "pomodoroSessionEditor"
            case .appBlock:
                return "appBlock"
            }
        }
    }
    
    enum TimerType: Identifiable, Equatable {
        case focus
        case reminder(ReminderModel)
        
        var id: String {
            switch self {
            case .focus:
                return "focus"
            case .reminder(let reminderModel):
                return "reminder_\(reminderModel.title)"
            }
        }
        
        var icon: Icon {
            switch self {
            case .focus:
                return .symbol(.timer)
            case .reminder(let reminderModel):
                return .init(reminderModel.icon)!
            }
        }
        
        var theme: LCHColor {
            switch self {
            case .focus:
                return Color.proSky
            case .reminder(let reminderModel):
                return .init(color: reminderModel.color)
            }
        }
        
        var title: String {
            switch self {
            case .focus:
                return "Focus"
            case .reminder(let reminderModel):
                return reminderModel.title
            }
        }
    }
    
    var sheetPresentation: Sheet?
    var timerItems: [TimerType] = [.focus]
    var selectedTimerItem: TimerType = .focus
    @ObservationIgnored
    var currentSelectedReminderIdx: Int = 0
    var panGestureTranslation: CGFloat = 0
    
    
    init(reminders: [ReminderModel]) {
        self.selectedTimerItem = .focus
        self.timerItems = [.focus] + reminders.map { .reminder($0) }
    }
    
    convenience init() {
        self.init(reminders: [])
    }
    
    
    func updateSelectedReminder(forwards: Bool, backwards: Bool) {
        if forwards && currentSelectedReminderIdx < timerItems.count - 1 {
            currentSelectedReminderIdx += 1
        } else if backwards && currentSelectedReminderIdx > 0 {
            currentSelectedReminderIdx -= 1
        } else {
            withAnimation(.snappy) {
                self.panGestureTranslation = 0
            }
        }
        
        self.selectedTimerItem = timerItems[currentSelectedReminderIdx]
    }
    
    func updateWithReminders(_ reminders: [ReminderModel]) {
        var newUpdatedItems: [TimerType] = [.focus]
        reminders.forEach { reminder in
            newUpdatedItems.append(.reminder(reminder))
        }
        self.timerItems = newUpdatedItems
    }
    
    
    // MARK: - Focus Session Attributes
    
    func focusSessionAttributes() -> FocusSessionAttributes {
        switch selectedTimerItem {
        case .focus:
            return .init(name: "Focus", color: Color.proSky, icon: .symbol(.timer), sessionType: nil, numberOfTasks: 0)
        case .reminder(let reminderModel):
            return .init(name: reminderModel.title, color: .init(color: reminderModel.color), icon: .init(reminderModel.icon) ?? Icon.symbol(.timer), sessionType: nil, numberOfTasks: reminderModel.tasks.count)
        }
    }
    
    func selectedReminder() -> ReminderModel? {
        switch selectedTimerItem {
        case .focus:
            return nil
        case .reminder(let reminderModel):
            return reminderModel
        }
    }
    
    
    // MARK: - App Block
    
    func appShieldConfiguration() -> CueShieldConfigurationModel {
        let focusSession: CueShieldConfigurationModel.FocusSession
        let theme: LCHColor
        let title: String
        let subtitle: String
        
        switch selectedTimerItem {
        case .focus:
            theme = Color.proSky
            let symbolColor = UIColor(theme.foregroundPrimary.resolved(for: .dark))
            let image = UIImage(systemSymbol: .timer).withTintColor(symbolColor, renderingMode: .alwaysTemplate).resized(size: .init(squared: 48))
            focusSession = .init(icon: image,
                                 color: theme.backgroundTertiary)
            title = "Stay Focused"
        case .reminder(let reminderModel):
            let reminderImage: UIImage?
            if let symbol = reminderModel.icon.symbol {
                reminderImage = .init(systemName: symbol)
            } else if let emoji = reminderModel.icon.emoji{
                reminderImage = UIImage.imageFromEmoji(.init(emoji), fontSize: nil, size: .init(squared: 48))
            } else {
                reminderImage = nil
            }
            
            theme = .init(color: reminderModel.color)
            focusSession = .init(icon: reminderImage ?? .init(systemSymbol: .questionmark),
                                 color: theme.backgroundTertiary)
            title = "Stay Focused on \(reminderModel.title)"
        }
        
        subtitle = "\nYou are currently in a focus session and have blocked \(CueShieldConfigurationModel.placeholder)"
        let titleColor = theme.foregroundSecondary.resolved(for: .dark)
        let subtitleColor = theme.foregroundTertiary.resolved(for: .dark)
        let primaryButtonForeground = Color.white
        let primaryButtonBackground = theme.baseColor
        
        let configuration = CueShieldConfigurationModel(focusSession: focusSession,
                                                        title: .init(title: title, color: titleColor),
                                                        subtitle: .init(title: subtitle, color: subtitleColor),
                                                        primaryButton: .init(title: "Remain Focused",
                                                                             foreground: primaryButtonForeground,
                                                                             background: primaryButtonBackground,
                                                                             response: .close),
                                                        secondaryButton: nil)
        return configuration
    }
}
