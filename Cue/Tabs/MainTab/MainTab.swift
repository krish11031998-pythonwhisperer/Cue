//
//  MainTab.swift
//  Cue
//
//  Created by Krishna Venkatramani on 17/01/2026.
//

import SwiftUI
import VanorUI
import Model
import Combine

struct IsTodayPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = true
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
    }
}

struct MainTab: View {
    
    typealias Tabs = MainTabViewModel.Tabs
    
    @Environment(Store.self) var store
    @Environment(SubscriptionManager.self) var subscriptionManager
    @State private var tabAccessorySize: CGSize = .zero
    
    // MARK:  FocusTabBottomAccessoryControl
    @Namespace var focusTimerTabNamespace: Namespace.ID
    @State private var viewModel: MainTabViewModel = .init()
    
    var createTabRole: TabRole {
        if #available(iOS 27.0, *) {
            return .prominent
        } else {
            return .search
        }
    }
    
    var bottomTabAccessories: Set<MainTabViewModel.Tabs> {
        return [.focus]
    }
    
    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            Tab(value: Tabs.home) {
                #if NEW_CALENDAR
                TodayCalendarView()
                #else
                TodayTabView {
                    self.viewModel.presentCreateReminder = true
                }
                .ignoresSafeArea(edges: .bottom)
                #endif
            } label: {
                Image(systemSymbol: .checkmarkCircleFill)
                    .font(.body)
                    .tint(Color.proSky.baseColor)
            }
            
            Tab(value: .calendar) {
                CalendarView {
                    self.viewModel.presentCreateReminder = true
                }
            } label: {
                Image(systemSymbol: .calendar)
                    .font(.body)
                    .tint(Color.proSky.baseColor)
            }
            
            Tab(value: .focus) {
                FocusTimerTabView(coordinator: viewModel.focusTimerCoordinator)
            } label: {
                Image(systemSymbol: .hourglass)
                    .font(.body)
                    .tint(Color.proSky.baseColor)
            }
            
            if subscriptionManager.userIsPro {
                Tab(value: .organize) {
                    OrangizeTabView()
                } label: {
                    Image(systemSymbol: .folder)
                        .font(.body)
                        .tint(Color.proSky.baseColor)
                }
            }
            
            Tab(value: .create, role: createTabRole) {
                Color.clear
            } label: {
                Image(systemSymbol: .plus)
                    .font(.body)
            }
        }
        .optionalBottomAccessoryView(selectedTab: viewModel.selectedTab, enabledTabs: bottomTabAccessories) { selectedTab in
            switch selectedTab {
            case .home:
                TodayTabBarAccessoryView(isToday: viewModel.isToday, todayPublisher: viewModel.todayPublisher)
            case .focus:
                FocusTabBottomAccessoryView(coordinator: viewModel.focusTimerCoordinator)
            default:
                EmptyView()
            }
        }
        .onPreferenceChange(IsTodayPreferenceKey.self, perform: {
            self.viewModel.isToday = $0
        })
        .tabBarMinimizeBehavior(.onScrollDown)
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: viewModel.selectedTab) { oldValue, newValue in
            print("(DEBUG) Change in selectedTab: ", viewModel.selectedTab)
            if newValue == .create {
                withAnimation(nil) {
                    self.viewModel.presentFloatingMenu = true
                    self.viewModel.selectedTab = oldValue
                }
            }
        }
        .overlay(alignment: .bottom) {
            if viewModel.presentFloatingMenu {
                CreationFloatingView(presentation: $viewModel.presentation, presentFloatingMenu: $viewModel.presentFloatingMenu)
            }
        }
        .cuePresentation(presentation: $viewModel.presentation, dismiss: viewModel.onDismiss(_:), contentBuilder: { presentation in
            switch presentation {
            case .createReminder:
                NavigationView {
                    NewCreateReminderView(mode: .create, store: store)
                }
                .presentationDetents([.fraction(1)])
            case .createReminderWithAI:
                NavigationView {
                    CueAIView(store: store)
                }
                .presentationDetents([.fraction(1)])
            case .onboarding:
                OnboardingMainView(store: store)
            case .paywall:
                CuePaywallView()
            }
        })
        .task {
            self.viewModel.focusAlarmManager.alarmManager = store.alarmManager
            self.viewModel.storeManager.store = store
        }
    }
    
}
