//
//  TodayTabView.swift
//  Cue
//
//  Created by Krishna Venkatramani on 19/01/2026.
//

import Foundation
import SwiftUI
import Model
import VanorUI
internal import EmojiKit
import Combine

extension CalendarDay: @retroactive CalendarDateCarouselDataElement, @retroactive Identifiable {
    public var id: Int {
        date.hashValue
    }
}

struct TodayTabView: View {

    @Environment(\.dismiss) var dismiss
    @Environment(Store.self) var store
    @Environment(SubscriptionManager.self) var subscriptionManager
    private var presentCreateReminder: () -> Void
    @State private var viewModel: TodayViewModel = .init()
    @State private var topPadding: CGFloat = .zero
    private let scrollToTodayPublisher: VoidPublisher
    
    init(scrollToTodayPublisher: VoidPublisher, presentCreateReminder: @escaping () -> Void) {
        self.scrollToTodayPublisher = scrollToTodayPublisher
        self.presentCreateReminder = presentCreateReminder
    }
    
    var id: Int {
        var hasher = Hasher()
        store.reminders.forEach { hasher.combine($0.hashValue) }
        return hasher.finalize()
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .center) {
                Color(uiColor: .systemBackground)
                if store.reminders.isEmpty {
                    ContentUnavailableView("No Reminders", systemImage: "bell.fill", description: descriptionText)
                        .font(.headline)
                } else {
                    tabView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.easeInOut) {
                            self.viewModel.fullPresentation = .settings
                        }
                    } label: {
                        Image(systemSymbol: .gearshape)
                            .font(.headline)
                    }
                }
                
                #if !KARINA_TESTING
                if subscriptionManager.userIsPro {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            print("(DEBUG) showTimer")
                            viewModel.presentation = .timer
                        } label: {
                            Image(systemSymbol: .timer)
                                .font(.headline)
                        }
                        .tint(Color.proSky.baseColor)
                    }
                }
                #endif
            }
        }
        .preference(key: IsTodayPreferenceKey.self, value: viewModel.todayCalendar?.date.startOfDay == viewModel.today.startOfDay)
        .onChange(of: viewModel.today, { _, _ in
            if store.user?.hapticsEnabled == true {
                SensoryFeedbackManager.shared.playSelection()                
            }
        })
        .task(id: store.reminders) {
            viewModel.setupCalendarForOneMonth(reminders: store.reminders)
        }
        .task {
            for await _ in store.hasLoggedReminder {
                viewModel.setupCalendarForOneMonth(reminders: store.reminders)
            }
        }
        .sheet(item: $viewModel.presentation, content: presentationContent(_:))
        .fullScreenCover(item: $viewModel.fullPresentation, content: fullScreenPresentationContent(_:))
        .onReceive(scrollToTodayPublisher) { _ in
            withAnimation(.easeInOut) {
                self.viewModel.today = Date.now.startOfDay
            }
        }
    }
    
    
    // MARK: - Presentation
    
    @ViewBuilder
    private func presentationContent(_ presentation: TodayViewModel.Presentation) -> some View {
        switch presentation {
        case .timer:
            TimerSheet(reminderModels: viewModel.reminderWithTimer) { selectedReminder, timeDuration in
                withAnimation {
                    self.viewModel.presentation = nil
                } completion: {
                    self.viewModel.fullPresentation = .focusTimer(selectedReminder, viewModel.reminderForTimerWithTasks(selectedReminder), timeDuration)
                }
            }
            .fittedPresentationDetent()
        }
    }
    
    @ViewBuilder
    private func fullScreenPresentationContent(_ presentation: TodayViewModel.FullScreenPresentation) -> some View {
        switch presentation {
        case .calendar:
            NavigationView {
                CalendarView {
                    self.dismiss()
                    self.presentCreateReminder()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("", systemSymbol: .xmark) {
                            dismiss()
                        }
                    }
                }
            }
        case .focusTimer(let reminderModel, let loggedReminderTasks, let duration):
            TimerView(reminder: reminderModel, loggedTasks: loggedReminderTasks, duration: duration)
        case .settings:
            SettingView()
        }
    }
    
    private func tabView() -> some View {
        TabView(selection: $viewModel.today) {
            ForEach(viewModel.calendarDay, id: \.date) { calendarDay in
                CalendarDayView(store: store, calendarDay: calendarDay, presentCreateReminder: presentCreateReminder)
                    .tag(calendarDay.date)
            }
        }
        .background {
            Color.cueItBackground
                .ignoresSafeArea(.all)
        }
        .environment(\.screenPadding, .init(topPadding: topPadding, bottomPadding: 83))
        .tabViewStyle(.page(indexDisplayMode: .never))
        .indexViewStyle(.page(backgroundDisplayMode: .never))
        .ignoresSafeArea(edges: .all)
        .safeAreaBar(edge: .top, alignment: .center, spacing: 0, content: {
            CalendarDateCarousel(dateElements: viewModel.calendarDay, selectedDate: viewModel.todayInCalendar)
                .background { Color.clear }
                .scrollIndicators(.hidden)
                .fixedSize(horizontal: false, vertical: true)
                .onGeometryChange(for: CGRect.self, of: { $0.frame(in: .global) }) { newValue in
                    self.topPadding = newValue.maxY
                }
                .disabled(true)
        })
    }
    
    
    // MARK: - DescriptionText
    
    private var descriptionText: Text {
        Text("Add Reminders to start organizing your day.")
            .font(.caption)
            .foregroundColor(.foregroundSecondary)
    }
}
