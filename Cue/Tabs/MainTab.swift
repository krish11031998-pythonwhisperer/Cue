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
    
    enum Tabs: Hashable {
        case home
        case organize
        case calendar
        case focus
        case create
    }
    
    enum Presentation: Int, Identifiable {
        case createReminder = 0
        case paywall
        
        var id: Int { rawValue }
    }
    
    enum FullScreenPresentation: String, Identifiable {
        case onboarding
        
        var id: String { rawValue }
    }
    
    @State private var isToday: Bool = true
    @Environment(Store.self) var store
    @Environment(SubscriptionManager.self) var subscriptionManager
    private let hasShowOnboarding: Bool
    @State private var selectedTab: Tabs = .home
    @State private var presentCreateReminder: Bool = false
    @State private var fullScreenPresentation: FullScreenPresentation? = nil
    @State private var presentPayWall: Bool = false
    private let presentPayWallAfterFirstOnboarding: Bool
    private let todayPublisher: PassthroughSubject<Void, Never> = .init()
    @State private var tabAccessorySize: CGSize = .zero
    
    // MARK:  FocusTabBottomAccessoryControl
    @Namespace var focusTimerTabNamespace: Namespace.ID
    @State private var focusTimerCoordinator: FocusTimerLaunchControlCoordinator! = nil
    let focusAlarmManager: FocusAlarmManager = .init()
    
    init() {
        self.hasShowOnboarding = CueUserDefaultsManager.shared[.hasShowOnboarding] ?? false
        presentPayWallAfterFirstOnboarding = !hasShowOnboarding
        self._focusTimerCoordinator = .init(initialValue: .init(alarmCoordinator: focusAlarmManager))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(value: Tabs.home) {
                TodayTabView(scrollToTodayPublisher: todayPublisher.eraseToAnyPublisher()) {
                    self.presentCreateReminder = true
                }
                .ignoresSafeArea(edges: .bottom)
            } label: {
                Label {
                    Text("")
                } icon: {
                    Image(systemSymbol: .checkmarkCircleFill)
                        .font(.body)
                }
                .tint(Color.proSky.baseColor)
            }
            
            Tab(value: .calendar) {
                CalendarView {
                    self.presentCreateReminder = true
                }
            } label: {
                Label {
                    Text("")
                } icon: {
                    Image(systemSymbol: .calendar)
                        .font(.body)
                }
                .tint(Color.proSky.baseColor)
            }
            
            Tab(value: .focus) {
                FocusTimerTabView(coordinator: focusTimerCoordinator)
            } label: {
                Image(systemSymbol: .hourglass)
                    .font(.body)
                    .tint(Color.proSky.baseColor)
            }
            
            if subscriptionManager.userIsPro {
                Tab(value: .organize) {
                    OrangizeTabView()
                } label: {
                    Label {
                        Text("")
                    } icon: {
                        Image(systemSymbol: .folder)
                            .font(.body)
                    }
                    .tint(Color.proSky.baseColor)
                }
            }
            
            if #available(iOS 27, *) {
                Tab(value: .create, role: .prominent) {
                    Color.clear
                } label: {
                    Image(systemSymbol: .plus)
                        .font(.body)
                }
            } else {
                Tab("", systemImage: "plus", value: .create, role: .search) {
                    Color.clear
                }
            }
        }
        .optionalBottomAccessoryView(selectedTab: selectedTab, enabledTabs: [.home, .focus]) { selectedTab in
            switch selectedTab {
            case .home:
                TodayTabBarAccessoryView(isToday: isToday, todayPublisher: todayPublisher)
            case .focus:
                FocusTabBottomAccessoryView(coordinator: focusTimerCoordinator)
            default:
                EmptyView()
            }
        }
//        .environment(\.tabAccessorySize, tabAccessorySize)
        .onPreferenceChange(IsTodayPreferenceKey.self, perform: {
            self.isToday = $0
        })
        .tabBarMinimizeBehavior(.onScrollDown)
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: selectedTab) { oldValue, newValue in
            print("(DEBUG) Change in selectedTab: ", selectedTab)
            if newValue == .create {
                self.presentCreateReminder = true
                self.selectedTab = oldValue
            }
        }
        .onChange(of: fullScreenPresentation, initial: false, { oldValue, newValue in
            if oldValue == .onboarding {
                self.presentCreateReminder = true
            }
        })
        .sheet(isPresented: $presentCreateReminder, onDismiss: {
            if presentPayWallAfterFirstOnboarding {
                presentPayWall = true
            }
        }) {
            CreateReminderRootView(store: store)
                .presentationDetents([.fraction(1)])
                .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $presentPayWall) {
            CuePaywallView()
                .presentationDetents([.fraction(1)])
        }
        .task {
            guard !hasShowOnboarding else { return }
            self.fullScreenPresentation = .onboarding
        }
        .fullScreenCover(item: $fullScreenPresentation) { fullScreenPresentation in
            switch fullScreenPresentation {
            case .onboarding:
                OnboardingMainView(store: store)
            @unknown default:
                fatalError("This shouldn't happen")
            }
        }
        .task {
            self.focusAlarmManager.alarmManager = store.alarmManager
        }
    }
    
}
