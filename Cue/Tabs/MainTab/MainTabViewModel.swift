//
//  MainTbViewModel.swift
//  Cue
//
//  Created by Krishna Venkatramani on 08/08/2026.
//

import SwiftUI
import VanorUI
import Combine

@Observable
@MainActor
class MainTabViewModel {
    
    enum Tabs: Hashable {
        case home
        case organize
        case calendar
        case focus
        case create
    }
    
    enum Presentation: Int, Hashable, Identifiable, CuePresentation {
        case createReminder = 0
        case createReminderWithAI
        case onboarding
        case paywall
        
        var id: Int { rawValue }
        
        var presentationType: CuePresentationType {
            switch self {
            case .createReminder:
                 return .fraction(1)
            case .createReminderWithAI:
                return .fraction(1)
            case .onboarding:
                return .fullScreen
            case .paywall:
                return .fraction(1)
            }
        }
    }
    
    var isToday: Bool = true
    var selectedTab: Tabs = .home
    var presentation: Presentation? = nil
    var presentPayWall: Bool = false
    var presentCreateReminder: Bool = false
    var presentFloatingMenu: Bool = false
    @ObservationIgnored
    var presentPayWallAfterFirstOnboarding: Bool
    
    let focusAlarmManager: FocusAlarmManager
    let focusTimerCoordinator: FocusSessionCoordinator
    let hasShowOnboarding: Bool
    let todayPublisher: PassthroughSubject<Void, Never> = .init()
    
    
    init() {
        let alarmManager = FocusAlarmManager()
        self.focusTimerCoordinator = .init(alarmCoordinator: alarmManager,
                                           liveActivityCoordinator: FocusLiveActivityManager())
        self.focusAlarmManager = alarmManager
        
        self.hasShowOnboarding = CueUserDefaultsManager.shared[.hasShowOnboarding] ?? false
        presentPayWallAfterFirstOnboarding = !hasShowOnboarding
        if !hasShowOnboarding {
            self.presentation = .onboarding
        }
    }
    
    
    func onDismiss(_ presenation: Presentation) {
        switch presenation {
        case .createReminder, .createReminderWithAI:
            if presentPayWallAfterFirstOnboarding {
                presentPayWallAfterFirstOnboarding = false
                presentation = .paywall
            }
        case .onboarding:
            CueUserDefaultsManager.shared[.hasShowOnboarding] = true
            presentation = .createReminder
        case .paywall:
            break
        }
    }
}

